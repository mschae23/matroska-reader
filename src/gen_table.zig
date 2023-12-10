const std = @import("std");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    // defer std.debug.assert(gpa.deinit() == .ok);
    // const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("../info/matroska_spec.txt", .{});
    defer file.close();

    const intermediate_reader = file.reader();
    var buffered_reader = std.io.bufferedReader(intermediate_reader);
    var reader = buffered_reader.reader();
    
    var buf: [256]u8 = .{@as(u8, 0)} ** 256;
    var fixedBufferStream = std.io.fixedBufferStream(&buf);
    const buf_writer = fixedBufferStream.writer();

    const output = try std.fs.cwd().createFile("./table.zig", .{});
    defer output.close();
    const writer = output.writer();
   
    try writer.writeAll("// This file is auto-generated.\n\npub const IdInfo = struct {\n    id: u32,\n    name: []const u8,\n};\n\npub const elements = [_]IdInfo {\n");

    const IdInfo = struct {
        id: u32,
        name: []const u8,
    };
    
    const ebml_elements = [_]IdInfo {
        IdInfo { .id = 0x1A45DFA3, .name = "EBML",                    },
        IdInfo { .id = 0x4286    , .name = "EBMLVersion",             },
        IdInfo { .id = 0x42F7    , .name = "EBMLReadVersion",         },
        IdInfo { .id = 0x42F2    , .name = "EBMLMaxIDLength",         },
        IdInfo { .id = 0x42F3    , .name = "EBMLMaxSizeLength",       },
        IdInfo { .id = 0x4282    , .name = "DocType",                 },
        IdInfo { .id = 0x4287    , .name = "DocTypeVersion",          },
        IdInfo { .id = 0x4285    , .name = "DocTypeReadVersion",      },
        IdInfo { .id = 0x4281    , .name = "DocTypeExtension",        },
        IdInfo { .id = 0x4283    , .name = "DocTypeExtensionName",    },
        IdInfo { .id = 0x4284    , .name = "DocTypeExtensionVersion", },
        IdInfo { .id = 0xEC      , .name = "Void",                    },
        IdInfo { .id = 0xBF      , .name = "CRC32",                   },
    };

    for (ebml_elements) |info| {
        std.debug.print("Found: {s} (ID 0x{X})\n", .{info.name, info.id});
        try writer.print("    IdInfo {{ .id = 0x{X}, .name = \"{s}\", }},\n", .{info.id, info.name});
    }

    while (true) {
        // std.debug.print("Loop\n", .{});

        fixedBufferStream.pos = 0;
        reader.streamUntilDelimiter(buf_writer, '\n', 256) catch |err| switch (err) {
            error.StreamTooLong, error.NoSpaceLeft => continue,
            error.EndOfStream => break,
            else => return err,
        };

        if (std.mem.startsWith(u8, &buf, "  <element name=\"")) {
            const name_start_pos: u8 = 17;
            var name_end_pos: u8 = 18;

            while (buf[name_end_pos] != '"' and name_end_pos <= buf.len) {
                name_end_pos += 1;
            }

            var id_start_pos: u8 = name_end_pos + 1;

            while ((buf[id_start_pos] != 'i' or buf[id_start_pos + 1] != 'd' or buf[id_start_pos + 2] != '=' or buf[id_start_pos + 3] != '"') and id_start_pos < buf.len - 4) {
                id_start_pos += 1;
            }

            if (id_start_pos == buf.len - 4) {
                continue;
            }

            id_start_pos += 4;
            var id_end_pos: u8 = id_start_pos + 1;

            while (buf[id_end_pos] != '"' and id_end_pos <= buf.len) {
                id_end_pos += 1;
            }

            const name = buf[name_start_pos..name_end_pos];
            const id = buf[id_start_pos..id_end_pos];

            std.debug.print("Found: {s} (ID {s})\n", .{name, id});

            if (std.mem.startsWith(u8, name, "EBML")) {
                std.debug.print("Skipping.\n", .{});
                continue;
            }

            try writer.print("    IdInfo {{ .id = {s}, .name = \"{s}\", }},\n", .{id, name});
        }
    }

    try writer.writeAll("};\n");
}