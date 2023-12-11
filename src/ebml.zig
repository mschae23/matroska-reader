const std = @import("std");

const log = std.log.scoped(.ebml);

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

pub inline fn getVintValue(vint: RawVint) u64 {
    var value = vint.raw;
    // std.debug.print("Value pre-and: {d} ({b})\n", .{value, value});
    value &= (~@as(u64, 0)) >> @as(u6, @intCast(vint.octets));
    // std.debug.print("Value pre-shift: {d} ({b})\n", .{value, value});
    value >>= @as(u6, @intCast(64 - 8 * vint.octets));
    return value;
}

pub inline fn readVint(reader: std.io.AnyReader) anyerror!u64 {
    return getVintValue(try readVintRaw(reader));
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
        // std.debug.print("Bytes: {b}\n", .{bytes});
        var stream = std.io.fixedBufferStream(&bytes);
        const reader = stream.reader().any();

        const value = try readVint(reader);
        // std.debug.print("Value: {d} ({b})\n", .{value, value});

        std.debug.assert(2 == value);
    }
}

pub inline fn readElementId(reader: std.io.AnyReader) anyerror!u32 {
    // Don't check whether the ID is encoded in an invalid way
    return try readVint(reader);
}

pub const UNKNOWN_DATA_SIZE: u64 = std.math.maxInt(u64);

pub inline fn readElementDataSize(reader: std.io.AnyReader) anyerror!u64 {
    const vint = try readVintRaw(reader);
    const value = getVintValue(vint);

    // std.debug.print("Reading element ID (octets: {d}, value: {d}, 0b{b}, 0x{X})\n", .{vint.octets, value, value, value});
    
    if (value == (@as(u64, 1) << @as(u6, @intCast(7 * vint.octets))) - 1) {
        // Element has an unknown data size. It is fine to use 2^64 - 1 (all u64 bits set to 1) as
        // a special indicator for that here, as that is out of bounds of the element data size value.
        return UNKNOWN_DATA_SIZE;
    } else {
        return value;
    }
}

test "UNKNOWN_DATA_SIZE value" {
    std.debug.assert(UNKNOWN_DATA_SIZE == ~@as(u64, 0));
}

test "readElementDataSize" {
    const a: u64 = 0b1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const b: u64 = 0b0100_0000_0111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const c: u64 = 0b0010_0000_0000_0000_0111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const d: u64 = 0b0111_1111_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const e: u64 = 0b0010_0000_0011_1111_1111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

    const vints = [5]u64 {a, b, c, d, e};
    var bytes: [5][8]u8 = .{.{0} ** 8} ** 5;
    var fixedBufferStreams: [5]std.io.FixedBufferStream([]u8) = .{undefined} ** 5;
    var readers: [5]std.io.AnyReader = .{undefined} ** 5;

    inline for (vints, 0..) |vint, i| {
        bytes[i] = comptime std.mem.toBytes(std.mem.nativeToBig(u64, vint));
        fixedBufferStreams[i] = std.io.fixedBufferStream(&bytes[i]);
        readers[i] = fixedBufferStreams[i].reader().any();
    }

    std.debug.assert(UNKNOWN_DATA_SIZE == try readElementDataSize(readers[0]));
    std.debug.assert(127 == try readElementDataSize(readers[1]));
    std.debug.assert(127 == try readElementDataSize(readers[2]));
    std.debug.assert(UNKNOWN_DATA_SIZE == try readElementDataSize(readers[3]));
    std.debug.assert(16_383 == try readElementDataSize(readers[4]));
}

// The following typed read functions assume element ID was already read in the buffer, meaning
// the buffer position is on the first byte of the element data size

pub fn readSignedInteger(reader: std.io.AnyReader, default: ?i64) anyerror!i64 {
    const size = try readElementDataSize(reader);
    
    if (size == 0) {
        return default orelse 0;
    } else if (size > 8) {
        return error.InvalidElementSize;
    } else {
        var bytes: [8]u8 = .{0} ** 8;
        try reader.readNoEof(bytes[0..size]);
        const value = std.mem.bigToNative(i64, std.mem.bytesToValue(i64, &bytes)) >> @as(u6, @intCast((8 - size) * 8));

        // std.debug.print("0b{b:0>64}, {d}\n", .{value, value});
        return value;
    }
}

test "Right-shift" {
    const bytes: [4]u8 = .{0b1111_0000, 0, 0, 0};
    var value = std.mem.bigToNative(i32, std.mem.bytesToValue(i32, &bytes));
    value >>= (4 - 1) * 8;
    std.debug.assert(-16 == value);
}

test "readSignedInteger" {
    const a: u64 = 0b1000_0010_1111_1110_1101_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const b: u64 = 0b1000_0001_0111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const c: u64 = 0b0010_0000_0000_0000_0000_0010_0000_0000_0111_1111_0000_0000_0000_0000_0000_0000;
    const d: u64 = 0b0100_0000_0000_0110_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
    const e: u64 = 0b1000_0100_0000_0000_0000_0000_0011_1111_1111_1111_0000_0000_0000_0000_0000_0000;
    const f: u64 = 0b1000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const g: u64 = 0b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

    const vints = [7]u64 {a, b, c, d, e, f, g};
    var bytes: [7][8]u8 = .{.{0} ** 8} ** 7;
    var fixedBufferStreams: [7]std.io.FixedBufferStream([]u8) = .{undefined} ** 7;
    var readers: [7]std.io.AnyReader = .{undefined} ** 7;

    inline for (vints, 0..) |vint, i| {
        bytes[i] = comptime std.mem.toBytes(std.mem.nativeToBig(u64, vint));
        fixedBufferStreams[i] = std.io.fixedBufferStream(&bytes[i]);
        readers[i] = fixedBufferStreams[i].reader().any();
    }

    // std.debug.print("\n", .{});
    std.debug.assert(-300 == try readSignedInteger(readers[0], null));
    std.debug.assert(127 == try readSignedInteger(readers[1], null));
    std.debug.assert(127 == try readSignedInteger(readers[2], null));
    std.debug.assert(-1 == try readSignedInteger(readers[3], null));
    std.debug.assert(16_383 == try readSignedInteger(readers[4], null));
    std.debug.assert(0 == try readSignedInteger(readers[5], null));
    fixedBufferStreams[5].pos = 0;
    std.debug.assert(0 == try readSignedInteger(readers[5], 70));
    std.debug.assert(0 == try readSignedInteger(readers[6], null));
    fixedBufferStreams[6].pos = 0;
    std.debug.assert(70 == try readSignedInteger(readers[6], 70));
}

pub fn readUnsignedInteger(reader: std.io.AnyReader, default: ?u64) anyerror!u64 {
    const size = try readElementDataSize(reader);
    
    if (size == 0) {
        return default orelse 0;
    } else if (size > 8) {
        return error.InvalidElementSize;
    } else {
        var bytes: [8]u8 = .{0} ** 8;
        try reader.readNoEof(bytes[0..size]);
        const value = std.mem.bigToNative(u64, std.mem.bytesToValue(u64, &bytes)) >> @as(u6, @intCast((8 - size) * 8));

        // std.debug.print("0b{b:0>64}, {d}\n", .{value, value});
        return value;
    }
}

test "readUnsignedInteger" {
    const a: u64 = 0b1000_0010_1111_1110_1101_0100_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const b: u64 = 0b1000_0001_0111_1111_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const c: u64 = 0b0010_0000_0000_0000_0000_0010_0000_0000_0111_1111_0000_0000_0000_0000_0000_0000;
    const d: u64 = 0b0100_0000_0000_0110_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111_1111;
    const e: u64 = 0b1000_0100_0000_0000_0000_0000_0011_1111_1111_1111_0000_0000_0000_0000_0000_0000;
    const f: u64 = 0b1000_0001_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;
    const g: u64 = 0b1000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000;

    const vints = [7]u64 {a, b, c, d, e, f, g};
    var bytes: [7][8]u8 = .{.{0} ** 8} ** 7;
    var fixedBufferStreams: [7]std.io.FixedBufferStream([]u8) = .{undefined} ** 7;
    var readers: [7]std.io.AnyReader = .{undefined} ** 7;

    inline for (vints, 0..) |vint, i| {
        bytes[i] = comptime std.mem.toBytes(std.mem.nativeToBig(u64, vint));
        fixedBufferStreams[i] = std.io.fixedBufferStream(&bytes[i]);
        readers[i] = fixedBufferStreams[i].reader().any();
    }

    // std.debug.print("\n", .{});
    std.debug.assert(65236 == try readUnsignedInteger(readers[0], null));
    std.debug.assert(127 == try readUnsignedInteger(readers[1], null));
    std.debug.assert(127 == try readUnsignedInteger(readers[2], null));
    std.debug.assert(281474976710655 == try readUnsignedInteger(readers[3], null));
    std.debug.assert(16_383 == try readUnsignedInteger(readers[4], null));
    std.debug.assert(0 == try readUnsignedInteger(readers[5], null));
    fixedBufferStreams[5].pos = 0;
    std.debug.assert(0 == try readUnsignedInteger(readers[5], 70));
    std.debug.assert(0 == try readUnsignedInteger(readers[6], null));
    fixedBufferStreams[6].pos = 0;
    std.debug.assert(70 == try readUnsignedInteger(readers[6], 70));
}

pub fn readFloat(reader: std.io.AnyReader, default: ?f64) anyerror!f64 {
    const size = try readElementDataSize(reader);
    
    if (size == 0) {
        return default orelse 0;
    } else if (size == 4) {
        var bytes: [4]u8 = .{0} ** 4;
        try reader.readNoEof(&bytes);
        const value = @as(f32, @bitCast(std.mem.bigToNative(u32, std.mem.bytesToValue(u32, &bytes))));
        return @as(f64, value);
    } else if (size == 8) {
        var bytes: [8]u8 = .{0} ** 8;
        try reader.readNoEof(&bytes);
        const value = @as(f64, @bitCast(std.mem.bigToNative(u64, std.mem.bytesToValue(u64, &bytes))));
        return value;
    } else {
        return error.InvalidElementSize;
    }
}

test "readFloat" {
    const a: f32 = 0.1;
    const b: f32 = 1.0;
    const c: f32 = 2.0;
    const d: f32 = 12345.67;
    const e: f64 = 0.0000000001;
    const f: f64 = 100.1001;
    const g: f64 = 999999999999999.0;
    const h: f64 = -0.0;

    const expected_32: [4]f32 = .{a, b, c, d};
    const expected_64: [4]f64 = .{e, f, g, h};

    inline for (expected_32) |expected| {
        const bytes = .{0b10000100} ++ std.mem.toBytes(std.mem.nativeToBig(u32, @bitCast(expected)));
        var fixedBufferStream = std.io.fixedBufferStream(&bytes);
        const reader = fixedBufferStream.reader().any();
        const value = try readFloat(reader, null);

        // std.debug.print("32, value: {d}\n", .{value});
        std.debug.assert(@as(f64, expected) == value);
    }

    inline for (expected_64) |expected| {
        const bytes = .{0b10001000} ++ std.mem.toBytes(std.mem.nativeToBig(u64, @bitCast(expected)));
        var fixedBufferStream = std.io.fixedBufferStream(&bytes);
        const reader = fixedBufferStream.reader().any();
        const value = try readFloat(reader, null);

        // std.debug.print("64, value: {d}\n", .{value});
        std.debug.assert(expected == value);
    }
}
