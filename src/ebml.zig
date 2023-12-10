const std = @import("std");

const io = @import("./io.zig");

pub const EbmlError = error {
    VintTooLarge,
};

pub const RawVint = struct {
    octets: u8,
    raw: u64,
};

pub fn readVintRaw(reader: std.io.AnyReader) anyerror!RawVint {
    const byte = try reader.readByte();
    // std.debug.print("Byte: {b}\n", .{byte});

    if (byte == 0) {
        // Vint is larger than 8 octets
        return EbmlError.VintTooLarge;
    }

    var octets: u8 = 1;

    while (byte >> @as(u3, @intCast(8 - octets)) != 1) { // 8 - octets should always be < 8, so u3
        octets += 1;
    }

    var bytes: [8]u8 = .{0} ** 8;
    bytes[0] = byte;

    if (octets != 1) { // octets > 1
        const read = try reader.readAll(bytes[1..octets]);

        if (read < octets - 1) {
            return error.EndOfStream;
        }
    }

    const value = std.mem.bigToNative(u64, std.mem.bytesToValue(u64, &bytes));
    return RawVint { .octets = octets, .raw = value, };
}

pub fn readVint(reader: std.io.AnyReader) anyerror!u64 {
    const vint = try readVintRaw(reader);
    var value = vint.raw;
    // std.debug.print("Value pre-and: {d} ({b})\n", .{value, value});
    value &= (~@as(u64, 0)) >> @as(u6, @intCast(vint.octets));
    // std.debug.print("Value pre-shift: {d} ({b})\n", .{value, value});
    value >>= @as(u6, @intCast(64 - 8 * vint.octets));
    return value;
}

test "readVint (2 in different sizes)" {
    const a: u32 = 0b1000_0010_0000_0000_0000_0000_0000_0000;
    const b: u32 = 0b0100_0000_0000_0010_0000_0000_0000_0000;
    const c: u32 = 0b0010_0000_0000_0000_0000_0010_0000_0000;
    const d: u32 = 0b0001_0000_0000_0000_0000_0000_0000_0010;

    const vints = [4]u32 {a, b, c, d};
    comptime var bytestreams: [4][4]u8 = .{.{0} ** 4} ** 4;

    inline for (vints, 0..) |vint, i| {
        bytestreams[i] = comptime std.mem.toBytes(std.mem.nativeToBig(u32, vint));
    }

    inline for (bytestreams) |bytes| {
        std.debug.print("Bytes: {b}\n", .{bytes});
        var stream = std.io.fixedBufferStream(&bytes);
        const reader = stream.reader().any();

        const value = try readVint(reader);
        std.debug.print("Value: {d} ({b})\n", .{value, value});

        std.debug.assert(2 == value);
    }
}

pub fn readElementId(reader: std.io.AnyReader) anyerror!u32 {
    return readVint(reader);
}
