const std = @import("std");

pub const PutBackError = error {
    OutOfMemory,
};

pub const ReadWriteStreamConfig = struct {
    read_buffer_size: usize = 4096,
    write_buffer_size: usize = 4096,
};

pub fn ReadWriteStream(
    comptime Context: type,
    comptime UnderlyingReadError: type,
    comptime UnderlyingWriteError: type,
    comptime UnderlyingSeekError: type,
    comptime UnderlyingGetSeekPosError: type,
    /// Returns the number of bytes read. It may be less than buffer.len.
    /// If the number of bytes read is 0, it means end of stream.
    /// End of stream is not an error condition.
    comptime readFn: fn (context: Context, buffer: []u8) UnderlyingReadError!usize,
    comptime writeFn: fn (context: Context, bytes: []const u8) UnderlyingWriteError!usize,
    comptime seekToFn: fn (context: Context, pos: u64) UnderlyingSeekError!void,
    comptime seekByFn: fn (context: Context, pos: i64) UnderlyingSeekError!void,
    comptime getPosFn: fn (context: Context) UnderlyingGetSeekPosError!u64,
    comptime getEndPosFn: fn (context: Context) UnderlyingGetSeekPosError!u64,
    comptime config: ReadWriteStreamConfig,
) type {
    return struct {
        context: Context,

        read_buf: [config.read_buffer_size]u8 = undefined,
        read_buf_start: usize = 0, read_buf_end: usize = 0,
        read_buf_peek_end: usize = 0,

        write_buf: [config.write_buffer_size]u8 = undefined,
        write_buf_end: usize = 0,

        // ReadWriteStream buffer usage
        // ============================
        //
        // x: undefined data
        // w: write buffer
        // p: peek data (part of read buffer)
        // r: read buffer
        // .: data yet to be read
        //
        // xxxxxxxxxxxxxxxxxxxxxxxxxwwwwwwwpppprrrrrrrrrrrrrrrrrrrrrrrrrrrr...
        // ^                        ^      ^   ^                           ^
        // |                        |      |   |                           |
        // |                        |      |   |                           read buffer end, underlying seek position
        // |                        |      |   start of the read buffer part got by read(), not putBack()
        // |                        |      user-facing seek position, start of read buffer
        // |                        start of write buffer
        // start of write buffer if it had maximum length
        //
        // == Operations ==
        // === Read ===
        // When reading:
        // - If the write buffer is not empty: (write buffer cannot be discontinous)
        //     - seek backwards by write_buf_offset
        //     - writeAll the write buffer
        //         - in case of error, seek back forwards to the previous position
        //         - If that fails, stream will be in an invalid state (return seek error)
        //     - seek back forwards by (write_buf_offset - write_buf_end)
        //         - If that fails, stream will be in an invalid state (return seek error)
        //     - set write_buf_offset = 0, set write_buf_end = 0
        // - Return as many bytes from the read byte buffer as exist
        // - If the read buffer is used up:
        //     - read from underlying stream, fill read buffer
        // - Repeat until dest has been filled, there has been an error or the underlying stream returns 0 bytes (EOF)
        //
        // === Write ===
        // If there is not enough space:
        //     Flush the write buffer.
        //     If the number of bytes to write is greater than the write buffer size,
        //       write directly to the underlying stream and return.
        //
        // If there is enough space in the write buffer:
        //     If the write buffer is empty:
        //         Set write_buf_offset = read_buf_end - read_buf_start
        //
        //     Append to the write buffer.
        //     Increment read_buf_start by number of bytes written (clamped to read_buf_end).
        //
        // === Flush write buffer ===
        // // TODO

        const Self = @This();
        pub const ReadError = UnderlyingReadError;
        pub const WriteError = UnderlyingWriteError;
        pub const SeekError = UnderlyingSeekError;
        pub const GetSeekPosError = UnderlyingGetSeekPosError;

        inline fn underlyingRead(self: Self, buffer: []u8) ReadError!usize {
            return readFn(self.context, buffer);
        }

        inline fn underlyingWrite(self: Self, bytes: []const u8) WriteError!usize {
            return writeFn(self.context, bytes);
        }

        inline fn underlyingSeekTo(self: Self, pos: u64) SeekError!void {
            return seekToFn(self.context, pos);
        }

        inline fn underlyingSeekBy(self: Self, amt: i64) SeekError!void {
            return seekByFn(self.context, amt);
        }

        pub inline fn getEndPos(self: Self) GetSeekPosError!u64 {
            return getEndPosFn(self.context);
        }

        pub inline fn getPos(self: Self) GetSeekPosError!u64 {
            return getPosFn(self.context);
        }

        pub fn read(self: *Self, dest: []u8) ReadError!usize {
            // Adapted from std.io.BufferedReader.read
            var dest_index: usize = 0;

            while (dest_index < dest.len) {
                const written = @min(dest.len - dest_index, self.read_buf_end - self.read_buf_start);
                @memcpy(dest[dest_index..][0..written], self.read_buf[self.read_buf_start..][0..written]);

                if (written == 0) {
                    // read_buf empty, fill it
                    const n = try self.underlyingRead(self.read_buf[0..]);

                    if (n == 0) {
                        // Reading from the underlying stream returned nothing,
                        // so we have nothing left to read.
                        return dest_index;
                    }

                    self.read_buf_start = 0;
                    self.read_buf_end = n;
                }

                self.read_buf_start += written;
                dest_index += written;
            }

            return dest.len;
        }

        pub fn flush_write(self: *Self) WriteError!void {
            // Adapted from std.io.BufferedWriter.flush
            var index: usize = 0;

            while (index != self.write_buf_end) {
                index += try self.write(self.write_buf[0..self.write_buf_end][index..]);
            }

            self.write_buf_end = 0;
        }

        pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
            // Adapted from std.io.BufferedWriter.write

            if (self.write_buf_end + bytes.len > self.write_buf.len) {
                try self.flush_write();

                if (bytes.len > self.write_buf.len) {
                    return self.underlyingWrite(bytes);
                }
            }

            const new_end = self.write_buf_end + bytes.len;

            @memcpy(self.write_buf[self.write_buf_end..new_end], bytes);
            self.write_buf_end = new_end;

            return bytes.len;
        }

        pub fn seekTo(self: *Self, pos: u64) SeekError!void {
            _ = self;
            _ = pos;

            // TODO
            unreachable;
        }

        pub fn seekBy(self: *Self, amt: i64) SeekError!void {
            _ = self;
            _ = amt;

            // TODO
            unreachable;
        }

        pub fn putBack(self: *Self, bytes: []const u8) PutBackError!void {
            _ = self;
            _ = bytes;

            // TODO
            unreachable;
        }

        pub fn putBackByte(self: *Self, byte: u8) PutBackError!void {
            return self.putBack(&[_]u8 { byte });
        }
    };
}

pub fn FileReadWriteStream(comptime config: ReadWriteStreamConfig) type {
    const File = std.fs.File;

    return ReadWriteStream(File,
        File.ReadError, File.WriteError, File.SeekError, File.GetSeekPosError,
        File.read, File.write, File.seekTo, File.seekBy, File.getEndPos, File.getPos,
        config);
}

pub fn streamFromFile(file: std.fs.File) FileReadWriteStream(.{}) {
    return FileReadWriteStream(.{}) {
        .context = file,
    };
}

pub fn FixedBufferReadWriteStream(comptime Buffer: type, comptime config: ReadWriteStreamConfig) type {
    const Fbs = std.io.FixedBufferStream(Buffer);

    return ReadWriteStream(*Fbs,
        Fbs.ReadError, Fbs.WriteError, Fbs.SeekError, Fbs.GetSeekPosError,
        Fbs.read, Fbs.write, Fbs.seekTo, Fbs.seekBy, Fbs.getEndPos, Fbs.getPos,
        config);
}

pub fn streamFromFixedBuffer(comptime Buffer: type, stream: *std.io.FixedBufferStream(Buffer)) FixedBufferReadWriteStream(Buffer, .{}) {
    return FixedBufferReadWriteStream(Buffer, .{}) {
        .context = stream,
    };
}
