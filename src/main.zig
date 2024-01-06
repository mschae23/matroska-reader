const std = @import("std");
const zigargs = @import("zigargs");

pub const io = @import("./io.zig");
pub const ebml = @import("./ebml/mod.zig");

const EbmlDocument = ebml.document.EbmlDocument;
const matroska = @import("./matroska_id_table.zig");

pub fn main() !u8 {
    var gpa = std.heap.GeneralPurposeAllocator(.{}) {};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const Options = struct {
        help: bool = false,
        version: bool = false,

        pub const shorthands = .{
            .h = "help",
            .v = "version",
        };

        pub const meta = .{
            .option_docs = .{
                .help = "Print this message and exit",
                .version = "Print version",
            }
        };
    };

    const options = zigargs.parseForCurrentProcess(Options, allocator, .print) catch return 1;
    defer options.deinit();

    if (options.options.help) {
        try zigargs.printHelp(Options, options.executable_name orelse "matroska-reader", std.io.getStdOut().writer());
        return 0;
    } else if (options.options.version) {
        const stdout = std.io.getStdOut().writer();
        try stdout.print("{s} {s}\n", .{options.executable_name orelse "matroska-reader", "0.1.0", });
        return 0;
    }

    if (options.positionals.len != 1) {
        std.debug.print("No file name provided.\n", .{});
        return 64; // USAGE
    }

    const HIDE_CLUSTERS_AND_CUES: bool = true;
    const STOP_AFTER_FIRST_CLUSTER: bool = false;

    const file = try std.fs.cwd().openFile(options.positionals[0], .{});
    defer file.close();

    var stream = io.streamFromFile(file);
    var document = try EbmlDocument(@TypeOf(stream)).init(allocator, &stream);
    defer document.deinit();

    try document.readHeader();

    std.debug.print("EBML document:\n  EBML version: {d}\n  EBML read version: {d}\n  EBML max ID length: {d}\n  EBML max size length: {d}\n  DocType: {s}\n  DocType version: {d}\n  DocType read version: {d}\n  DocType extensions: {d}\n", .{
        document.ebml_version, document.ebml_read_version, document.ebml_max_id_length, document.ebml_max_size_length, document.doctype, document.doctype_version, document.doctype_read_version, document.doctype_extensions.items.len});

    for (document.doctype_extensions.items) |extension| {
        std.debug.print("  - Name: {s}\n    Version: {d}\n", .{extension.name, extension.version});
    }

    var id = try document.readElementId();

    while (id.id == matroska.ID_Void) {
        _ = try document.skipElement();
        id = try document.readElementId();
    }

    try std.testing.expectEqual(@as(u64, matroska.ID_Segment), id.id);
    try document.readMaster(id);

    var element_type: matroska.ElementType = .binary;

    document.trimPath();

    while (document.path_len > 0) {
        id = try document.readElementId();

        for (0..(document.path_len - 1)) |_| {
            std.debug.print("  ", .{});
        }

        search: {
            inline for (matroska.HOT_ELEMENTS) |item| {
                if (id.id == item.id) {
                    std.debug.print("{s}:", .{item.name});
                    element_type = item.type;
                    break :search;
                }
            }

            inline for (matroska.IMPORTANT_ELEMENTS) |item| {
                if (id.id == item.id) {
                    std.debug.print("{s}:", .{item.name});
                    element_type = item.type;
                    break :search;
                }
            }

            inline for (matroska.ELEMENTS) |item| {
                if (id.id == item.id) {
                    std.debug.print("{s}:", .{item.name});
                    element_type = item.type;
                    break :search;
                }
            }

            element_type = .binary;
            std.debug.print("Unknown element with ID 0x{X}:", .{id.id});
        }

        switch (element_type) {
            .integer, .date => {
                std.debug.print(" {d}\n", .{try document.readSignedInteger(null)});
            },
            .uinteger => {
                std.debug.print(" {d}\n", .{try document.readUnsignedInteger(null)});
            },
            .float => {
                std.debug.print(" {d}\n", .{try document.readFloat(null)});
            },
            .string, .utf8 => {
                const string = try document.readBinaryAllAlloc(allocator, 256);
                defer allocator.free(string);
                std.debug.print(" \"{s}\"\n", .{string});
            },
            .master => {
                if (HIDE_CLUSTERS_AND_CUES and (id.id == matroska.ID_Cluster or id.id == matroska.ID_Cues)) {
                    // To avoid spam
                    std.debug.print(" hidden\n", .{});
                    _ = try document.skipElement();
                } else {
                    std.debug.print("\n", .{});
                    try document.readMaster(id);
                }
            },
            .binary => {
                std.debug.print(" {d} bytes\n", .{try document.skipElement()});
            },
        }

        document.trimPath();

        if (STOP_AFTER_FIRST_CLUSTER and id.id == matroska.ID_Cluster) {
            std.debug.print("Stopping after first cluster.\n", .{});
            break;
        }
    }

    return 0;
}

test {
    std.testing.refAllDecls(@This());
}
