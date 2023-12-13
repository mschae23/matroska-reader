const std = @import("std");

pub const GenericIoError = error {
    Io,
};

pub const ReadError = GenericIoError;

pub const WriteError = error {
    Unwritable,
} || GenericIoError;

pub const SeekError = error {
    Unseekable,
} || GenericIoError;

pub const GetSeekPosError = SeekError;

pub const PutBackError = error {
    OutOfMemory,
};

pub const ReadWriteStreamConfig = struct {
    read_buffer_size: usize = 4096,
    write_buffer_size: usize = 4096,
};

pub fn ReadWriteStream(
    comptime Context: type,
    /// Returns the number of bytes read. It may be less than buffer.len.
    /// If the number of bytes read is 0, it means end of stream.
    /// End of stream is not an error condition.
    comptime readFn: fn (context: Context, buffer: []u8) GenericIoError!usize,
    comptime writeFn: fn (context: Context, bytes: []const u8) WriteError!usize,
    comptime seekToFn: fn (context: Context, pos: u64) SeekError!void,
    comptime seekByFn: fn (context: Context, pos: i64) SeekError!void,
    comptime getPosFn: fn (context: Context) GetSeekPosError!u64,
    comptime getEndPosFn: fn (context: Context) GetSeekPosError!u64,
    comptime config: ReadWriteStreamConfig,
) type {
    return struct {
        context: Context,

        read_buf: [config.read_buffer_size]u8 = undefined,
        read_buf_start: usize = 0, read_buf_end: usize = 0,
        read_buf_peek_start: usize = 0,

        write_buf: [config.write_buffer_size]u8 = undefined,
        write_buf_end: usize = 0,

        const Self = @This();

        inline fn unbufferedRead(self: Self, buffer: []u8) ReadError!usize {
            return readFn(self.context, buffer);
        }

        inline fn unbufferedWrite(self: Self, bytes: []const u8) WriteError!usize {
            return writeFn(self.context, bytes);
        }

        inline fn rawSeekTo(self: Self, pos: u64) SeekError!void {
            return seekToFn(self.context, pos);
        }

        inline fn rawSeekBy(self: Self, amt: i64) SeekError!void {
            return seekByFn(self.context, amt);
        }

        pub inline fn getEndPos(self: Self) GetSeekPosError!u64 {
            return getEndPosFn(self.context);
        }

        pub inline fn getPos(self: Self) GetSeekPosError!u64 {
            return getPosFn(self.context);
        }

        pub fn read(self: *Self, buffer: []u8) ReadError!usize {
            _ = self;
            _ = buffer;

            // TODO
            unreachable;
        }

        pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
            _ = self;
            _ = bytes;

            // TODO
            unreachable;
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

inline fn fileRead(file: std.fs.File, buffer: []u8) ReadError!usize {
    return file.read(buffer) catch return error.Io;
}

inline fn fileWrite(file: std.fs.File, bytes: []const u8) WriteError!usize {
    return file.write(bytes) catch return error.Io;
}

inline fn fileSeekTo(file: std.fs.File, pos: u64) SeekError!void {
    // std.os uses SeekError.Unseekable for both IO errors and actual unseekable files,
    // so we just use error.Io in these functions for both.
    return file.seekTo(pos) catch return error.Io;
}

inline fn fileSeekBy(file: std.fs.File, amt: i64) SeekError!void {
    return file.seekBy(amt) catch return error.Io;
}

inline fn fileGetEndPos(file: std.fs.File) GetSeekPosError!u64 {
    return file.getEndPos() catch return error.Io;
}

inline fn fileGetPos(file: std.fs.File) GetSeekPosError!u64 {
    return file.getPos() catch return error.Io;
}

pub fn FileReadWriteStream(comptime config: ReadWriteStreamConfig) type {
    return ReadWriteStream(std.fs.File, fileRead, fileWrite, fileSeekTo, fileSeekBy, fileGetEndPos, fileGetPos, config);
}

pub fn streamFromFile(file: std.fs.File) FileReadWriteStream(.{}) {
    return FileReadWriteStream(.{}) {
        .context = file,
    };
}

// TODO Implement a function to create a ReadWriteStream from a FixedBufferStream
