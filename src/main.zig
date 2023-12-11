const std = @import("std");
const zigargs = @import("zigargs");

pub const ebml = @import("./ebml.zig");

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

    return 0;
}

test {
    std.testing.refAllDecls(@This());
}
