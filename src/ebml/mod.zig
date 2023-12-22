pub const primitive = @import("./primitive.zig");
pub const document = @import("./document.zig");

test {
    const std = @import("std");
    std.testing.refAllDecls(@This());
}
