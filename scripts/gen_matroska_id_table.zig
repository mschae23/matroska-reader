const std = @import("std");

const MATROSKA_VERSION: u8 = 4;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const file = try std.fs.cwd().openFile("./matroska_schema.xml", .{});
    defer file.close();

    const intermediate_reader = file.reader();
    var buffered_reader = std.io.bufferedReader(intermediate_reader);
    var reader = buffered_reader.reader();

    var buf: [256]u8 = .{@as(u8, 0)} ** 256;
    var fixedBufferStream = std.io.fixedBufferStream(&buf);
    const buf_writer = fixedBufferStream.writer();

    const output = try std.fs.cwd().createFile("../src/matroska_id_table.zig", .{});
    defer output.close();
    const writer = output.writer();

    try writer.print("// This file was auto-generated.\n\npub const MATROSKA_VERSION: u8 = {d};\n\npub const ElementType = enum {{\n    integer,\n    uinteger,\n    float,\n    string,\n    date,\n    utf8,\n    master,\n    binary,\n}};\n\npub const Importance = enum {{\n    hot,\n    important,\n    default,\n}};\n\npub const ElementInfo = struct {{\n    id: u32,\n    type: ElementType,\n    name: []const u8,\n    importance: Importance = .default,\n    deprecated: bool = false,\n}};\n\npub const IdInfo = struct {{\n    id: u32,\n    type: ElementType,\n    name: []const u8,\n}};\n\npub const ELEMENTS = [_]ElementInfo {{\n", .{MATROSKA_VERSION});

    const ElementType = enum {
        integer,
        uinteger,
        float,
        string,
        date,
        utf8,
        master,
        binary,

        pub fn toString(self: @This()) []const u8 {
            return switch (self) {
                .integer => "integer",
                .uinteger => "uinteger",
                .float => "float",
                .string => "string",
                .date => "date",
                .utf8 => "utf8",
                .master => "master",
                .binary => "binary",
            };
        }
    };

    const IdInfo = struct {
        id: u32,
        type: ElementType,
        name: []const u8,
        deprecated: bool,
    };

    const ebml_elements = [_]IdInfo {
        IdInfo { .id = 0x1A45DFA3, .type = .master,   .name = "EBML",                    .deprecated = false, },
        IdInfo { .id = 0x4286    , .type = .uinteger, .name = "EBMLVersion",             .deprecated = false, },
        IdInfo { .id = 0x42F7    , .type = .uinteger, .name = "EBMLReadVersion",         .deprecated = false, },
        IdInfo { .id = 0x42F2    , .type = .uinteger, .name = "EBMLMaxIDLength",         .deprecated = false, },
        IdInfo { .id = 0x42F3    , .type = .uinteger, .name = "EBMLMaxSizeLength",       .deprecated = false, },
        IdInfo { .id = 0x4282    , .type = .string,   .name = "DocType",                 .deprecated = false, },
        IdInfo { .id = 0x4287    , .type = .uinteger, .name = "DocTypeVersion",          .deprecated = false, },
        IdInfo { .id = 0x4285    , .type = .uinteger, .name = "DocTypeReadVersion",      .deprecated = false, },
        IdInfo { .id = 0x4281    , .type = .master,   .name = "DocTypeExtension",        .deprecated = false, },
        IdInfo { .id = 0x4283    , .type = .string,   .name = "DocTypeExtensionName",    .deprecated = false, },
        IdInfo { .id = 0x4284    , .type = .uinteger, .name = "DocTypeExtensionVersion", .deprecated = false, },
        IdInfo { .id = 0xEC      , .type = .binary,   .name = "Void",                    .deprecated = false, },
        IdInfo { .id = 0xBF      , .type = .binary,   .name = "CRC32",                   .deprecated = false, },
    };

    const hot_elements = [_][]const u8 {
        "Cluster",
        "SimpleBlock",
        "Timestamp",
    };

    const important_elements = [_][]const u8 {
        "Segment",
        "Info",
        "TimestampScale",
        "Cluster",
        "Timestamp",
        "SimpleBlock",
        "BlockGroup",
        "Block",
        "BlockDuration",
        "Tracks",
        "TrackEntry",
        "TrackNumber",
        "TrackType",
        "CodecID",
        "CodecPrivate",
        "Video",
        "PixelWidth",
        "PixelHeight",
        "Audio",
        "SamplingFrequency",
        "Channels",
        "ContentCompression",
    };

    for (ebml_elements) |info| {
        std.debug.print("Found: {s} (ID 0x{X})\n", .{info.name, info.id});
        try writer.print("    ElementInfo {{ .id = 0x{X}, .type = .{s}, .name = \"{s}\", }},\n", .{info.id, info.type.toString(), info.name, });
    }

    var hot_info = std.ArrayList(IdInfo).init(allocator);
    defer hot_info.deinit();

    var important_info = std.ArrayList(IdInfo).init(allocator);
    defer important_info.deinit();

    var all_info = std.ArrayList(IdInfo).init(allocator);
    defer all_info.deinit();

    defer {
        for (all_info.items) |info| {
            allocator.free(info.name);
        }
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

            while ((buf[id_start_pos] != 'i' or buf[id_start_pos + 1] != 'd' or buf[id_start_pos + 2] != '=' or buf[id_start_pos + 3] != '"') and id_start_pos < fixedBufferStream.pos - 4) {
                id_start_pos += 1;
            }

            if (id_start_pos == fixedBufferStream.pos - 4) {
                continue;
            }

            id_start_pos += 4;
            var id_end_pos: u8 = id_start_pos + 1;

            while (buf[id_end_pos] != '"' and id_end_pos <= fixedBufferStream.pos) {
                id_end_pos += 1;
            }

            var type_start_pos = id_end_pos + 1;

            while (!std.mem.startsWith(u8, buf[type_start_pos..buf.len], "type=\"") and type_start_pos < fixedBufferStream.pos - 6) {
                type_start_pos += 1;
            }

            std.debug.assert(type_start_pos != fixedBufferStream.pos - 6);

            type_start_pos += 6;
            var type_end_pos = type_start_pos + 1;

            while (buf[type_end_pos] != '"' and type_end_pos < fixedBufferStream.pos) {
                type_end_pos += 1;
            }

            std.debug.assert(buf[type_end_pos] == '"');

            var maxver_start_pos = id_end_pos + 1;
            var max_version: u8 = 4;

            while (!std.mem.startsWith(u8, buf[maxver_start_pos..buf.len], "maxver=\"") and maxver_start_pos < fixedBufferStream.pos - 8) {
                maxver_start_pos += 1;
            }

            if (maxver_start_pos != fixedBufferStream.pos - 8) {
                maxver_start_pos += 8;
                var maxver_end_pos = maxver_start_pos + 1;

                while (buf[maxver_end_pos] != '"' and maxver_end_pos < fixedBufferStream.pos) {
                    maxver_end_pos += 1;
                }

                std.debug.assert(buf[maxver_end_pos] == '"');
                max_version = try std.fmt.parseUnsigned(u8, buf[maxver_start_pos..maxver_end_pos], 10);
            }

            const name = buf[name_start_pos..name_end_pos];
            const kind = buf[type_start_pos..type_end_pos];
            const id = buf[id_start_pos..id_end_pos];

            const parsed_type: ElementType =
                if (std.mem.eql(u8, kind, "integer")) .integer
                else if (std.mem.eql(u8, kind, "uinteger")) .uinteger
                else if (std.mem.eql(u8, kind, "float")) .float
                else if (std.mem.eql(u8, kind, "string")) .string
                else if (std.mem.eql(u8, kind, "date")) .date
                else if (std.mem.eql(u8, kind, "utf-8")) .utf8
                else if (std.mem.eql(u8, kind, "master")) .master
                else if (std.mem.eql(u8, kind, "binary")) .binary
                else return error.InvalidType;

            std.debug.print("Found: {s} (ID {s}, type: {s})\n", .{name, id, parsed_type.toString()});

            if (std.mem.startsWith(u8, name, "EBML")) {
                std.debug.print("Skipping.\n", .{});
                continue;
            }

            var hot = false;
            var important = false;
            const deprecated = max_version < MATROSKA_VERSION;
            const parsed_id = try std.fmt.parseUnsigned(u32, id, 0);
            const duped_name = try allocator.dupe(u8, name);

            for (hot_elements) |element| {
                if (std.mem.eql(u8, element, name)) {
                    hot = true;
                    try hot_info.append(IdInfo { .id = parsed_id, .type = parsed_type, .name = duped_name, .deprecated = deprecated, });
                    break;
                }
            }

            if (!hot) {
                for (important_elements) |element| {
                    if (std.mem.eql(u8, element, name)) {
                        important = true;
                        try important_info.append(IdInfo { .id = parsed_id, .type = parsed_type, .name = duped_name, .deprecated = deprecated, });
                        break;
                    }
                }
            }

            try all_info.append(IdInfo { .id = parsed_id, .type = parsed_type, .name = duped_name, .deprecated = deprecated, });
            try writer.print("    ElementInfo {{ .id = {s}, .type = .{s}, .name = \"{s}\", {s}{s}}},\n", .{id, parsed_type.toString(), name, if (hot) ".importance = .hot, " else if (important) ".importance = .important, " else "", if (deprecated) ".deprecated = true, " else "" });
        }
    }

    try writer.writeAll("};\n\npub const HOT_ELEMENTS = [_]IdInfo {\n");

    for (hot_info.items) |info| {
        try writer.print("    IdInfo {{ .id = 0x{X}, .type = .{s}, .name = \"{s}\" }},\n", .{info.id, info.type.toString(), info.name});
    }

    try writer.writeAll("};\n\npub const IMPORTANT_ELEMENTS = [_]IdInfo {\n");

    for (important_info.items) |info| {
        try writer.print("    IdInfo {{ .id = 0x{X}, .type = .{s}, .name = \"{s}\" }},\n", .{info.id, info.type.toString(), info.name});
    }

    try writer.writeAll("};\n\n");

    for (all_info.items) |info| {
        try writer.print("pub const ID_{s}: u32 = 0x{X};{s}\n", .{info.name, info.id, if (info.deprecated) " // Deprecated" else "", });
    }
}
