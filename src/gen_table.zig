const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("../info/matroska_spec.txt", .{});
    defer file.close();

    const intermediate_reader = file.reader();
    var buffered_reader = std.io.bufferedReader(intermediate_reader);
    var reader = buffered_reader.reader();
    
    var buf: [64]u8 = .{@as(u8, 0)} ** 64;
    var fixedBufferStream = std.io.fixedBufferStream(&buf);
    const buf_writer = fixedBufferStream.writer();

    const output = try std.fs.cwd().createFile("./table.zig", .{});
    defer output.close();
    const writer = output.writer();
   
    try writer.writeAll("// This file is auto-generated.\n\npub const IdInfo = struct {\n    id: u32,\n    name: []const u8,\n};\n\npub const elements = [_]IdInfo {\n");

    while (true) {
        fixedBufferStream.pos = 0;
        reader.streamUntilDelimiter(buf_writer, '\n', 64) catch |err| switch (err) {
            error.StreamTooLong, error.NoSpaceLeft => continue,
            error.EndOfStream => return,
            else => return err,
        };

        if (std.mem.startsWith(u8, &buf, "6.")) {
            break;
        }

        if (std.mem.startsWith(u8, &buf, "5.1.")) {
            var pos: u8 = 4;

            if (buf[pos] != ' ') {
                while (buf[pos] >= '0' and buf[pos] <= '9' or buf[pos] == '.') {
                    pos += 1;
                }

                if (buf[pos] != ' ') {
                    continue;
                }
            }

            std.debug.assert(buf[pos] == ' ');
            std.debug.assert(buf[pos + 1] == ' ');
            pos += 2;

            var pos_2: u8 = pos + 1;

            while (buf[pos_2] != ' ') {
                pos_2 += 1;
            }

            const name = try allocator.dupe(u8, buf[pos..pos_2]);
            defer allocator.free(name);

            fixedBufferStream.pos = 0;
            try reader.streamUntilDelimiter(buf_writer, '0', 64);
            fixedBufferStream.pos = 0;
            try reader.streamUntilDelimiter(buf_writer, ' ', 64);

            const id = buf[0..fixedBufferStream.pos];
            std.debug.print("Found: {s} (ID 0{s})\n", .{name, id});

            try writer.print("    IdInfo {{ .id = 0{s}, .name = \"{s}\", }},\n", .{id, name});
        }
    }

    try writer.writeAll("};\n");
}