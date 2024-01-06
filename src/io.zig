//! The IO module provides the [`ReadWriteStream`] struct for buffered reading from and writing to a byte stream.
//!
//! [`ReadWriteStream`]: ReadWriteStream

const std = @import("std");

/// Error that can occur in any operation when the [`ReadWriteStream`] is an invalid state.
/// It can only be reset by seeking to a known position.
///
/// [`ReadWriteStream`]: ReadWriteStream
pub const UnrecoverableError = error {
    Unrecoverable,
};


/// Compile-time configuration of [`ReadWriteStream`]. It allows customizing the size of the read and
/// write buffers used.
///
/// [`ReadWriteStream`]: ReadWriteStream
pub const ReadWriteStreamConfig = struct {
    read_buffer_size: usize = 4096,
    write_buffer_size: usize = 4096,
};

/// `ReadWriteStream` wraps a byte stream that is readable and optionally writable or seekable.
/// It provides buffering for both reading and writing, as well as supporting peeking (using [`putBack`]).
///
/// All functions in this struct assume that the underlying stream is not be modified externally between function calls, which can
/// cause unexpected behaviour.
///
/// Instances for [`File`s] or [`FixedBufferStream`s] can be created using [`streamFromFile`] and
/// [`streamFromFixedBuffer`], respectively.
///
/// [`putBack`]: ReadWriteStream.putBack
/// [`File`s]: std.fs.File
/// [`FixedBufferStream`s]: std.io.FixedBufferStream
/// [`streamFromFile`]: streamFromFile
/// [`streamFromFixedBuffer`]: streamFromFixedBuffer
///
pub fn ReadWriteStream(
    /// The type of the context value passed to the underlying functions.
    comptime Context: type,
    /// The type of errors returned by the underlying read function.
    comptime UnderlyingReadError: type,
    /// The type of errors returned by the underlying write function.
    comptime UnderlyingWriteError: type,
    /// The type of errors returned by the underlying seek function.
    comptime UnderlyingSeekError: type,
    /// The type of errors returned by the underlying `getSeekPos` function.
    comptime UnderlyingGetSeekPosError: type,
    /// Calling this function is **not** part of the public API.
    ///
    /// Returns the number of bytes read. It may be less than `buffer.len`.
    /// If the number of bytes read is `0`, it means end of stream.
    /// End of stream is not an error condition.
    ///
    /// If this returns an error, it must not have changed the seek position of the underlying stream.
    comptime readFn: fn (context: Context, buffer: []u8) UnderlyingReadError!usize,
    /// Calling this function is **not** part of the public API.
    ///
    /// Returns the number of bytes written. it may be less than `buffer.len`.
    /// If the number of bytes supplied is non-zero, this will also be non-zero.
    ///
    /// If this returns an error, it must not have changed the seek position of the underlying stream.
    comptime writeFn: fn (context: Context, bytes: []const u8) UnderlyingWriteError!usize,
    /// Calling this function is **not** part of the public API.
    comptime seekToFn: fn (context: Context, pos: u64) UnderlyingSeekError!void,
    /// Calling this function is **not** part of the public API.
    comptime seekByFn: fn (context: Context, amt: i64) UnderlyingSeekError!void,
    /// Calling this function is **not** part of the public API.
    comptime getPosFn: fn (context: Context) UnderlyingGetSeekPosError!u64,
    /// Calling this function is **not** part of the public API.
    comptime getEndPosFn: fn (context: Context) UnderlyingGetSeekPosError!u64,
    /// The compile-time configuration of this `ReadWriteStream`. Allows configuring the
    /// sizes of the read and write buffer, respectively.
    comptime config: ReadWriteStreamConfig,
) type {
    return struct {
        /// This is **not** part of the public API.
        ///
        /// `context` is a value passed to the underlying read, write, and seek functions.
        context: Context,

        /// If the stream is in an invalid state (usually due to a write buffer flush failing
        /// after some data has already been written), this state is recorded here to have
        /// subsequent calls to other functions return an error.
        /// It is cleared by [`seekTo`].
        ///
        /// [`seekTo`]: seekTo
        unrecoverable: bool = false,

        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// The memory of the read buffer. Only `read_buf[0..read_buf_end]`
        /// contains valid values, although usually only `read_buf[read_buf_start..read_buf_end]`
        /// is used, as [`read_buf_start`] is the current user-facing position, i. e. it is the
        /// index of the next value to be delivered by [`read`].
        ///
        /// [`read_buf_start`]: ReadWriteStream.read_buf_start
        /// [`read`]: ReadWriteStream.read
        read_buf: [config.read_buffer_size]u8 = undefined,
        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// Represents the user-facing seek position relative to index `0` of the read buffer.
        /// `read_buf[read_buf_start..read_buf_end]` is the slice that will be returned by
        /// the next call to [`read`].
        ///
        /// Must be less than or equal to [`read_buf_end`]. If they are equal, they should both
        /// be `0`.
        ///
        /// [`read`]: ReadWriteStream.read
        /// [`read_buf_end`]: ReadWriteStream.read_buf_end
        read_buf_start: usize = 0,
        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// Stores the index of the end of the read buffer (exclusive). Values in the read buffer
        /// beyond this index are considered uninitialized memory.
        read_buf_end: usize = 0,

        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// The memory of the write buffer. Only `write_buf[0..write_buf_end]` contains valid values,
        /// although under normal circumstances, only `write_buf[write_buf_start..write_buf_end]` is used, as
        /// [`write_buf_start`] is only set to a non-zero value when a write buffer flush has failed
        /// part-way through for error recovery.
        ///
        /// [`write_buf_start`]: ReadWriteStream.write_buf_start
        write_buf: [config.write_buffer_size]u8 = undefined,
        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// Stores the index of the start of the write buffer. This will usually be `0`. Values before
        /// this index are considered to have already been written to the underlying stream.
        write_buf_start: usize = 0,
        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// Stores the index of the end of the write buffer. As long as [`write`] keeps being called,
        /// this index will continually increase until the buffer has been filled, at which point
        /// `write_buf[write_buf_start..write_buf_end]` will be flushed.
        ///
        /// [`write`]: ReadWriteStream.write
        write_buf_end: usize = 0,
        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// The write buffer offset is the current seek position relative to `read_buf_start`. This will usually be `0`, but if the
        /// read buffer is unused (it is `read_buf_start` and `read_buf_end` are equal to `0`), this makes it possible to still return
        /// an accurate user-facing seek position in `getPos()`.
        write_buf_offset: usize = 0,

        /// This is **not** part of the public API. Modifying this value is unsafe.
        ///
        /// The current user-facing seek position in the stream.
        position: usize = 0,

        const Self = @This();

        /// The type of errors that can occur while flushing the write buffer.
        pub const WriteFlushError = UnderlyingWriteError || UnderlyingSeekError || UnrecoverableError;
        /// The type of errors that can occur during writing.
        pub const WriteError = WriteFlushError;
        /// The type of errors that can occur during seeking.
        pub const SeekError = UnderlyingSeekError || WriteFlushError;
        /// The type of errors that can occur during reading.
        pub const ReadError = UnderlyingReadError || WriteFlushError;
        /// The type of errors that can occur when calling [`getSeekPos`].
        ///
        /// [`getSeekPos`]: getSeekPos
        pub const GetSeekPosError = UnderlyingGetSeekPosError;
        /// The type of errors that can occur when calling [`putBack`].
        ///
        /// [`putBack`]: putBack
        pub const PutBackError = WriteFlushError || UnderlyingSeekError;

        /// Returns the number of bytes read. It may be less than `buffer.len`.
        /// If the number of bytes read is `0`, it means end of stream.
        /// End of stream is not an error condition.
        ///
        /// If this returns an error, it must not have changed the seek position of the underlying stream.
        inline fn underlyingRead(self: Self, buffer: []u8) UnderlyingReadError!usize {
            return readFn(self.context, buffer);
        }

        /// Returns the number of bytes written. it may be less than `buffer.len`.
        /// If the number of bytes supplied is non-zero, this will also be non-zero.
        ///
        /// If this returns an error, it must not have changed the seek position of the underlying stream.
        inline fn underlyingWrite(self: Self, bytes: []const u8) UnderlyingWriteError!usize {
            return writeFn(self.context, bytes);
        }

        inline fn underlyingSeekTo(self: Self, pos: u64) UnderlyingSeekError!void {
            return seekToFn(self.context, pos);
        }

        inline fn underlyingSeekBy(self: Self, amt: i64) UnderlyingSeekError!void {
            return seekByFn(self.context, amt);
        }

        inline fn underlyingGetPos(self: Self) UnderlyingGetSeekPosError!u64 {
            return getPosFn(self.context);
        }

        pub inline fn getEndPos(self: Self) GetSeekPosError!u64 {
            return getEndPosFn(self.context);
        }

        // ReadWriteStream buffer usage
        // ============================
        //
        // == Diagram ==
        // These diagrams show how the bytes of the read and write buffers are used. They assume a buffer size of 32 bytes for both kinds.
        //
        // === Legend ===
        // x: undefined data
        // w: write buffer
        // |: separator for read / write buffer data (left of it is write buffer, right is read buffer)
        // p: peek data (part of read buffer)
        // r: read buffer
        // .: data yet to be read
        //
        // === Example ===
        // wwwwwwwxxxxxxxxxxxxxxxxxxxxxxxxx|pppprrrrrrrrrrrrrrrrrrrrrxxxxxxx...
        // ^      ^                         ^   ^                    ^
        // |      |                         |   |                    |
        // |      |                         |   |                    read buffer end, underlying seek position
        // |      |                         |   start of the read buffer part got by read(), not putBack()
        // |      |                         user-facing seek position, start of read buffer
        // |      write buffer end, treated as the first byte of the read buffer (as if wwwwwww|pppprrr... was continous)
        // start of write buffer (write_buf_start, usually == 0)
        //
        // After reading 8 bytes:
        // wwwwwwwxxxxxxxxxxxxxxxxxxxxxxxxx|rrrrrrrrrrrrrrrrrrrrrrrrrxxxxxxx...
        //                                  ^       ^
        //                                  |       |
        //                                  |       user-facing seek position always remains at the start of the read buffer
        //                                  This part of the read buffer is still accessible by seeking back up to 8 bytes
        // The underlying seek position remained unchanged.
        // If the user wants to write now, the write buffer *has* to be flushed.
        //
        // == Operations ==
        // === Read ===
        // When reading:
        // - If write buffer is not empty (write buffer cannot be discontinous):
        //     - Flush the write buffer.
        //
        // - Return as many bytes from the read byte buffer as exist
        // - If the read buffer is used up:
        //     - Read from underlying stream, fill read buffer
        // - Repeat until dest has been filled, there has been an error or the underlying stream returns 0 bytes (EOF)
        //
        // === Write ===
        // If there is not enough space in the write buffer:
        //     Flush the write buffer.
        //     If the number of bytes to write is greater than the write buffer size,
        //       write directly to the underlying stream and return.
        //
        // If there is enough space in the write buffer:
        //     If the write buffer is empty:
        //         Set write_buf_offset = read_buf_end - read_buf_start
        //
        //     Append to the write buffer.
        //     Increment write_buf_end by number of bytes written.
        //     Increment read_buf_start by number of bytes written (clamped to read_buf_end).
        //
        // === Flush write buffer ===
        // - Seek backwards to start of written data in the underlying stream
        // - writeAll the write buffer
        //     - In case of error, seek back forwards to the previous position
        //         - If that fails, stream will be in an invalid state (return seek error)
        // - overwrite the relevant part of the read buffer
        // - Seek back forwards
        //     - If that fails, stream will be in an invalid state (return seek error)
        // - Set write_buf_offset = 0, set write_buf_end = 0, set write_buf_start = 0
        //
        // === Put back ===
        // Flush write buffer if it is not empty.
        //     Rationale:
        //         If the write buffer is non-empty, the last action cannot have been a read.
        //         Is putting back bytes that were just written a reasonable action to support?
        //         When flushing, this will just work by default.
        //
        // If the number of bytes to put back is <=read_buf_start:
        //     Decrement read_buf_start by number of bytes to put back and return.
        //
        // Otherwise, discard read buffer. Place the supplied bytes anywhere in the read buffer and
        // set read_buf_start and read_buf_end accordingly.
        //
        // They should probably just be put at the start, however, that will prevent further calls to putBack
        // from reusing the same buffer. However, the most likely pattern is probably: read -> putBack -> read etc.
        // If putting it at the start:
        //     Set read_buf_start = 0, read_buf_end = number of bytes
        //
        // === Seek by ===
        // - If write buffer is not empty (write buffer cannot be discontinous):
        //     - Flush the write buffer.
        //
        // - If read_buf_start + amt < read_buf_end or read_buf_start + amt >= 0
        //     - Increment read_buf_start by amt
        //
        // - Otherwise, same implementation as seekTo().
        //
        // === Seek to ===
        // Flush write buffer if it is non-empty.
        // Use underlying seekTo().
        // Set all *_buf_start, *_buf_end and write_buf_offset = 0, discarding them.

        pub fn read(self: *Self, dest: []u8) ReadError!usize {
            if (self.unrecoverable) {
                // per-branch cold
                return error.Unrecoverable;
            }

            std.debug.print("Read {d} bytes\n", .{dest.len});

            if (!self.isWriteBufferEmpty()) {
                try self.flushWrite();
                // No need to worry about the write buffer now
            }

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
                self.position += written;
                dest_index += written;
            }

            return dest.len;
        }

        pub fn write(self: *Self, bytes: []const u8) WriteError!usize {
            if (self.unrecoverable) {
                // per-branch cold
                return error.Unrecoverable;
            }

            std.debug.print("Write {d} bytes\n", .{bytes.len});

            if (self.write_buf_end + bytes.len > self.write_buf.len) {
                try self.flushWrite();

                if (bytes.len > self.write_buf.len) {
                    return self.underlyingWrite(bytes);
                }
            }

            const new_end = self.write_buf_end + bytes.len;

            @memcpy(self.write_buf[self.write_buf_end..new_end], bytes);
            self.write_buf_end = new_end;

            const previous_read_start = self.read_buf_start;
            self.read_buf_start = @min(self.read_buf_start + bytes.len, self.read_buf_end);
            self.write_buf_offset += (previous_read_start + bytes.len) - self.read_buf_start;
            self.position += bytes.len;

            if (self.read_buf_start == self.read_buf_end and self.read_buf_start != 0 and previous_read_start + bytes.len > self.read_buf_start) {
                self.read_buf_end = 0;
                self.read_buf_start = 0;
            }

            return bytes.len;
        }

        pub fn flushWrite(self: *Self) WriteFlushError!void {
            if (self.unrecoverable) {
                // per-branch cold
                return error.Unrecoverable;
            }

            std.debug.print("Flush write ({d}..{d})\n", .{self.write_buf_start, self.write_buf_end});

            var seek_by: usize = if (self.read_buf_end != 0) self.read_buf_end - self.read_buf_start + self.write_buf_end - self.write_buf_start else 0;

            if (seek_by != 0) {
                try self.underlyingSeekBy(-@as(i64, @intCast(seek_by)));
            }

            const end = self.write_buf_end - self.write_buf_start;

            {
                const len = @min(self.read_buf_start, end);
                const write_start = self.write_buf_start + (end - len);

                if (write_start < self.write_buf_end) {
                    @memcpy(self.read_buf[(self.read_buf_start - len) .. self.read_buf_start], self.write_buf[write_start..self.write_buf_end]);
                }
            }

            var index: usize = 0;

            while (index != end) {
                // std.debug.print("Iterate ({d}..{d}, index: {d}, end: {d})\n", .{self.write_buf_start, self.write_buf_end, index, end});

                if (self.underlyingWrite(self.write_buf[self.write_buf_start..self.write_buf_end][index..])) |written| {
                    // std.debug.print("Success\n", .{});
                    index += written;
                } else |err| {
                    // std.debug.print("Error: {}\n", .{err});
                    self.write_buf_start += index;
                    seek_by -|= index;

                    if (seek_by != 0) {
                        self.underlyingSeekBy(@intCast(seek_by)) catch |seek_err| {
                            self.unrecoverable = true;
                            return seek_err; // TODO Return `err` or `seek_err` here?
                        };
                    }

                    return err;
                }
            }

            if (seek_by != 0) {
                self.underlyingSeekBy(@intCast(seek_by)) catch |seek_err| {
                    self.unrecoverable = true;
                    return seek_err;
                };
            }

            self.write_buf_end = 0;
            self.write_buf_start = 0;
            self.write_buf_offset = 0;
        }

        /// Discards the read and write buffers. Any data written so far that wasn't successfully flushed to
        /// the underlying stream will be lost.
        ///
        /// This function also resets the `unrecoverable` flag. However, it makes no guarentees on the current seek position,
        /// which may still be at any unknown point within the stream. It is recommended to use [`seekTo`] to seek to a known
        /// position before continuing.
        ///
        /// [`seekTo`]: seekTo
        pub fn discardBuffers(self: *Self) void {
            std.debug.print("Discard buffers\n", .{});
            self.read_buf_end = 0;
            self.read_buf_start = 0;
            self.write_buf_end = 0;
            self.write_buf_start = 0;
            self.write_buf_offset = 0;
            self.unrecoverable = false;
        }

        /// Seeks to the given position in the stream.
        pub fn seekTo(self: *Self, pos: u64) SeekError!void {
            std.debug.print("Seek to {d}\n", .{pos});

            if (!self.isWriteBufferEmpty()) {
                try self.flushWrite();
            }

            self.discardBuffers();
            self.position = pos;
            return self.underlyingSeekTo(pos);
        }

        /// Seeks to the given position in the stream, discarding the read and write buffers. Any data written so far that wasn't
        /// successfully flushed to the underlying stream will be lost.
        ///
        /// This function also resets the `unrecoverable` flag, so it can be used to seek to a known position after an error to retry.
        pub fn seekToDiscarding(self: *Self, pos: u64) UnderlyingSeekError!void {
            std.debug.print("Seek to {d} (discarding)\n", .{pos});

            self.discardBuffers();
            self.position = pos;
            return self.underlyingSeekTo(pos);
        }

        pub fn seekBy(self: *Self, amt: i64) SeekError!void {
            if (self.unrecoverable) {
                // per-branch cold
                return error.Unrecoverable;
            }

            std.debug.print("Seek by {d} bytes\n", .{amt});

            if (!self.isWriteBufferEmpty()) {
                try self.flushWrite();
            }

            if (@as(i64, @intCast(self.read_buf_start)) + amt < @as(i64, @intCast(self.read_buf_end)) and @as(i64, @intCast(self.read_buf_start)) + amt >= 0) {
                std.debug.print("Reusing read buffer for seek\n", .{});
                self.read_buf_start = @intCast(@as(i64, @intCast(self.read_buf_start)) + amt);
            } else {
                std.debug.print("Discarding buffers for seek\n", .{});
                try self.underlyingSeekBy(amt - @as(i64, @intCast(self.read_buf_end)) + @as(i64, @intCast(self.read_buf_start)));
                self.read_buf_end = 0;
                self.read_buf_start = 0;
            }

            self.position = @intCast(@as(i64, @intCast(self.position)) + amt);
        }

        pub fn getPos(self: *const Self) GetSeekPosError!u64 {
            // // std.debug.print("Get position: underlying: {d}, read: {d}..{d}, write offset: {d}, write: {d}..{d}\n", .{try self.underlyingGetPos(), self.read_buf_start, self.read_buf_end, self.write_buf_offset, self.write_buf_start, self.write_buf_end});
            // return try self.underlyingGetPos() + self.read_buf_start - self.read_buf_end + self.write_buf_offset;
            return self.position;
        }

        /// Puts back `bytes` into the stream, so they will be read again.
        ///
        /// This function simply assumes that `bytes` contains the exact bytes that were read or written directly before this call.
        /// That is, if `bytes` was modified after reading, it is unspecified whether a call to `read` following this function will return
        /// the modified data or the data that is actually in the underlying stream.
        pub fn putBack(self: *Self, bytes: []const u8) PutBackError!void {
            if (self.unrecoverable) {
                // per-branch cold
                return error.Unrecoverable;
            }

            std.debug.print("Put back {d} bytes\n", .{bytes.len});

            if (!self.isWriteBufferEmpty()) {
                try self.flushWrite();
            }

            if (bytes.len <= self.read_buf_start) {
                self.read_buf_start -= bytes.len;
            } else if (bytes.len > self.read_buf.len) {
                // Don't use `bytes`, just seek by the number of bytes needed to read these again
                try self.underlyingSeekBy(@intCast(-@as(i64, @intCast(self.read_buf_end)) + @as(i64, @intCast(self.read_buf_start)) - @as(i64, @intCast(bytes.len))));
                self.read_buf_end = 0;
                self.read_buf_start = 0;
            } else { // bytes.len > self.read_buf_start && bytes.len <= self.read_buf_len
                try self.underlyingSeekBy(@intCast(@as(i64, @intCast(self.read_buf_end)) + @as(i64, @intCast(self.read_buf_start))));

                @memcpy(self.read_buf[0..bytes.len], bytes);
                self.read_buf_start = 0;
                self.read_buf_end = bytes.len;
            }

            self.position -= bytes.len;
        }

        /// Puts back a single byte `byte` into the stream, so it will be read again.
        ///
        /// This function simply assumes that `byte` is the exact byte that was read or written directly before this call.
        /// That is, if `byte` was modified after reading, it is unspecified whether a call to `read` following this function will return
        /// the modified data or the data that is actually in the underlying stream.
        pub inline fn putBackByte(self: *Self, byte: u8) PutBackError!void {
            return self.putBack(&[_]u8{byte});
        }

        inline fn isWriteBufferEmpty(self: *const Self) bool {
            std.debug.print("Is write buffer empty ({d}..{d})\n", .{self.write_buf_start, self.write_buf_end});
            return self.write_buf_end == self.write_buf_start; // end - start == 0
        }

        pub inline fn any(self: *Self) AnyReadWriteStream(config) {
            return AnyReadWriteStream(config) {
                .context = @ptrCast(self),
                .readFn = typeErasedReadFn,
                .writeFn = typeErasedWriteFn,
                .flushWriteFn = typeErasedFlushWriteFn,
                .discardBuffersFn = typeErasedDiscardBuffersFn,
                .seekToFn = typeErasedSeekToFn,
                .seekToDiscardingFn = typeErasedSeekToDiscardingFn,
                .seekByFn = typeErasedGetPosFn,
                .putBackFn = typeErasedPutBackFn,
                .getPosFn = typeErasedGetPosFn,
                .getEndPosFn = typeErasedGetEndPosFn,
            };
        }

        pub inline fn any_reader(self: *Self) std.io.AnyReader {
            return std.io.AnyReader {
                .context = @ptrCast(self),
                .readFn = typeErasedReadFn,
            };
        }

        fn typeErasedReadFn(context: *const anyopaque, buffer: []u8) anyerror!usize {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return read(ptr, buffer);
        }

        fn typeErasedWriteFn(context: *const anyopaque, bytes: []const u8) anyerror!usize {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return write(ptr.*, bytes);
        }

        fn typeErasedFlushWriteFn(context: *const anyopaque) anyerror!void {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return flushWrite(ptr.*);
        }

        fn typeErasedDiscardBuffersFn(context: *const anyopaque) void {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return discardBuffers(ptr.*);
        }

        fn typeErasedSeekToFn(context: *const anyopaque, pos: u64) anyerror!void {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return seekTo(ptr, pos);
        }

        fn typeErasedSeekToDiscardingFn(context: *const anyopaque, pos: u64) anyerror!void {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return seekToDiscarding(ptr, pos);
        }

        fn typeErasedSeekByFn(context: *const anyopaque, amt: i64) anyerror!void {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return seekBy(ptr, amt);
        }

        fn typeErasedPutBackFn(context: *const anyopaque, bytes: []const u8) anyerror!void {
            const ptr: *Self = @constCast(@ptrCast(@alignCast(context)));
            return putBack(ptr, bytes);
        }

        fn typeErasedGetPosFn(context: *const anyopaque) anyerror!u64 {
            const ptr: *const Self = @alignCast(@ptrCast(context));
            return getPos(ptr);
        }

        fn typeErasedGetEndPosFn(context: *const anyopaque) anyerror!u64 {
            const ptr: *const Self = @alignCast(@ptrCast(context));
            return getEndPos(ptr);
        }
    };
}

pub fn FileReadWriteStream(comptime config: ReadWriteStreamConfig) type {
    const File = std.fs.File;

    return ReadWriteStream(File, File.ReadError, File.WriteError, File.SeekError, File.GetSeekPosError, File.read, File.write, File.seekTo, File.seekBy, File.getPos, File.getEndPos, config);
}

pub fn streamFromFile(file: std.fs.File) FileReadWriteStream(.{}) {
    return FileReadWriteStream(.{}){
        .context = file,
    };
}

pub fn FixedBufferReadWriteStream(comptime Buffer: type, comptime config: ReadWriteStreamConfig) type {
    const Fbs = std.io.FixedBufferStream(Buffer);

    return ReadWriteStream(*Fbs, Fbs.ReadError, Fbs.WriteError, Fbs.SeekError, Fbs.GetSeekPosError, Fbs.read, Fbs.write, Fbs.seekTo, Fbs.seekBy, Fbs.getPos, Fbs.getEndPos, config);
}

pub fn streamFromFixedBuffer(comptime Buffer: type, stream: *std.io.FixedBufferStream(Buffer)) FixedBufferReadWriteStream(Buffer, .{}) {
    return FixedBufferReadWriteStream(Buffer, .{}) {
        .context = stream,
    };
}

pub const AnyReadWriteStream = struct {
    context: *anyopaque,
    readFn: *const fn (context: *anyopaque, buffer: []u8) anyerror!usize,
    writeFn: *const fn (context: *anyopaque, bytes: []const u8) anyerror!usize,
    flushWriteFn: *const fn (context: *anyopaque) anyerror!void,
    discardBuffersFn: *const fn (context: *anyopaque) void,
    seekToFn: *const fn (context: *anyopaque, pos: u64) anyerror!void,
    seekToDiscardingFn: *const fn (context: *anyopaque, pos: u64) anyerror!void,
    seekByFn: *const fn (context: *anyopaque, amt: i64) anyerror!void,
    putBackFn: *const fn (context: *anyopaque, bytes: []const u8) anyerror!void,
    getPosFn: *const fn (context: *const anyopaque) anyerror!u64,
    getEndPosFn: *const fn (context: *const anyopaque) anyerror!u64,

    pub inline fn read(self: AnyReadWriteStream, buffer: []u8) anyerror!usize {
        return self.readFn(self.context, buffer);
    }

    pub inline fn write(self: AnyReadWriteStream, bytes: []const u8) anyerror!usize {
        return self.writeFn(self.context, bytes);
    }

    pub inline fn flushWrite(self: AnyReadWriteStream) anyerror!void {
        return self.flushWriteFn(self.context);
    }

    pub inline fn discardBuffers(self: AnyReadWriteStream) void {
        return self.discardBuffersFn(self.context);
    }

    pub inline fn seekTo(self: AnyReadWriteStream, pos: u64) anyerror!void {
        return self.seekToFn(self.context, pos);
    }

    pub inline fn seekToDiscarding(self: AnyReadWriteStream, pos: u64) anyerror!void {
        return self.seekToDiscardingFn(self.context, pos);
    }

    pub inline fn seekBy(self: AnyReadWriteStream, amt: i64) anyerror!void {
        return self.seekByFn(self.context, amt);
    }

    pub inline fn putBack(self: AnyReadWriteStream, bytes: []const u8) anyerror!void {
        return self.putBackFn(self.context, bytes);
    }

    pub inline fn putBackByte(self: AnyReadWriteStream, byte: u8) anyerror!void {
        return self.putBack(&[_]u8{byte});
    }

    pub inline fn getPos(self: AnyReadWriteStream) anyerror!u64 {
        return self.getPosFn(self.context);
    }

    pub inline fn getEndPos(self: AnyReadWriteStream) anyerror!u64 {
        return self.getEndPosFn(self.context);
    }
};

test "ReadWriteStream on a fixed buffer - mixed" {
    var buffer: [64]u8 = .{undefined} ** 64;

    for (0.., &buffer) |i, *value| {
        value.* = @intCast(i);
    }

    std.debug.print("00. Setup\n", .{});
    var fixed_buf = std.io.fixedBufferStream(&buffer);
    var stream = streamFromFixedBuffer([]u8, &fixed_buf);

    std.debug.assert(64 == try stream.getEndPos());

    var temp: [4]u8 = .{0xFF} ** 4;

    std.debug.print("01. Read\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(0 == try stream.getPos());
    std.debug.assert(4 == try stream.read(&temp));
    std.debug.assert(std.mem.eql(u8, &.{0, 1, 2, 3}, &temp));

    std.debug.print("\n02. Write\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(4 == try stream.getPos());
    temp = .{9, 8, 7, 6};
    std.debug.assert(4 == try stream.write(&temp));

    // Buffered, so shouldn't be in the backing array yet
    std.debug.assert(std.mem.eql(u8, &.{4, 5, 6, 7}, buffer[4..8]));

    std.debug.print("\n03. Seek\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(8 == try stream.getPos());
    try stream.seekBy(-4);

    std.debug.print("\n04. Read\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(4 == try stream.getPos());
    std.debug.assert(4 == try stream.read(&temp));
    std.debug.print("{any}\n", .{temp});
    std.debug.assert(std.mem.eql(u8, &.{9, 8, 7, 6}, &temp));
    std.debug.assert(std.mem.eql(u8, &.{9, 8, 7, 6}, buffer[4..8]));

    std.debug.print("\n05. Read\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(8 == try stream.getPos());
    std.debug.assert(4 == try stream.read(&temp));
    std.debug.assert(std.mem.eql(u8, &.{8, 9, 10, 11}, &temp));

    std.debug.print("\n06. Put back\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(12 == try stream.getPos());
    try stream.putBack(temp[2..]);

    std.debug.print("\n07. Read\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(10 == try stream.getPos());
    std.debug.assert(4 == try stream.read(&temp));
    std.debug.assert(std.mem.eql(u8, &.{10, 11, 12, 13}, &temp));

    std.debug.print("\n08. Seek by\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(14 == try stream.getPos());
    try stream.seekBy(47);

    std.debug.print("\n09. Get pos\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(61 == try stream.getPos());
    std.debug.assert(64 == try stream.getEndPos());

    std.debug.print("\n10. Read\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(3 == try stream.read(&temp));
    std.debug.print("Read: {any}\n", .{temp});
    std.debug.assert(std.mem.eql(u8, &.{61, 62, 63, 13}, &temp));

    std.debug.print("\n11. Read\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(64 == try stream.getPos());
    std.debug.assert(0 == try stream.read(&temp));

    std.debug.print("\n12. Write past end\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    // Even though the backing stream does not support more than 64 bytes, this will succeed, as the bytes will be
    // stored in the write buffer
    temp = .{0xA0, 0xA1, 0xA2, 0xA3};
    std.debug.assert(64 == try stream.getPos());
    std.debug.assert(4 == try stream.write(&temp));

    std.debug.print("\n13. Flush write past end\n", .{});
    // std.debug.print("Pos: {d}, underlying: {d}, read buffer: {d}..{d}\n", .{try stream.getPos(), try stream.underlyingGetPos(), stream.read_buf_start, stream.read_buf_end});
    std.debug.assert(68 == try stream.getPos());
    std.debug.assert(error.NoSpaceLeft == stream.flushWrite());
}

test "ReadWriteStream on a fixed buffer - read only" {
    var buffer: [64]u8 = .{undefined} ** 64;

    for (0.., &buffer) |i, *value| {
        value.* = @intCast(i);
    }

    var fixed_buf = std.io.fixedBufferStream(&buffer);
    var stream = streamFromFixedBuffer([]u8, &fixed_buf);

    var temp: [1]u8 = .{0xFF};

    for (0..buffer.len) |i| {
        std.debug.assert(1 == try stream.read(&temp));
        std.debug.assert(i == temp[0]);
        std.debug.assert(i + 1 == try stream.getPos());
    }

    std.debug.assert(0 == try stream.read(&temp));
    std.debug.assert(buffer.len - 1 == temp[0]);
    std.debug.assert(buffer.len == try stream.getPos());
}

test "ReadWriteStream on a fixed buffer - write only" {
    var buffer: [64]u8 = .{0xFF} ** 64;

    var fixed_buf = std.io.fixedBufferStream(&buffer);
    var stream = streamFromFixedBuffer([]u8, &fixed_buf);

    var temp: [1]u8 = .{0xFF};

    for (0..buffer.len) |i| {
        temp[0] = @intCast(i);
        std.debug.assert(1 == try stream.write(&temp));
        std.debug.assert(i + 1 == try stream.getPos());
    }

    std.debug.assert(std.mem.eql(u8, &(.{0xFF} ** 64), &buffer));

    try stream.flushWrite();

    for (0..buffer.len) |i| {
        std.debug.assert(i == buffer[i]);
    }

    temp[0] = buffer.len;
    std.debug.assert(1 == try stream.write(&temp));
    std.debug.assert(buffer.len + 1 == try stream.getPos());
    std.debug.assert(error.NoSpaceLeft == stream.flushWrite());
}
