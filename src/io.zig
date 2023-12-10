const std = @import("std");

pub const InputStream = struct {
    reader: std.io.AnyReader,
    seeker: std.fs.File.SeekableStream,
};
