const std = @import("std");

const log = std.log.scoped(.ebml);

const io = @import("../io.zig");
const primitive = @import("./primitive.zig");

const EbmlError = primitive.EbmlError;

const matroska = @import("../matroska_id_table.zig");

/// The version of EBML supported by this reader.
///
/// At the time of writing, only EBML version 1 exists.
pub const EBML_VERSION: u8 = 1;
const VINTMAX: u64 = primitive.VINTMAX;

/// The maximum depth of nested master elements supported by this EBML reader.
pub const MAX_NESTING_DEPTH: u8 = 16;

const ElementId = primitive.ElementId;

pub const MasterElementNestData = struct {
    id: ElementId,
    end_pos: usize,
};

/// Represents a version of a DocType extension.
pub const DoctypeExtension = struct {
    name: []const u8, // Owned by EbmlDocument
    version: u32,
};

/// Represents a single EBML document, and stores information found in the EBML header.
///
/// It also holds the [`Reader`] and an optional [`SeekableStream`] of the input byte stream, as well as the current path of nested
/// EBML master elements.
///
/// [`Reader`]: std.io.AnyReader
/// [`SeekableStream`]: std.io.SeekableStream
pub fn EbmlDocument(comptime ReadWriteStream: type) type {
    return struct {
        /// The allocator is used for runtime-sized data found in the EBML header. Currently, this is only used for the
        /// DocType names and extension list.
        ///
        /// This allocator **should not** be used by API users of `EbmlDocument`.
        allocator: std.mem.Allocator,
        /// The underlying byte stream that this `EbmlDocument` is being read from or written to.
        stream: *ReadWriteStream,

        /// Version of EBML, as specified by the `EBMLVersion` element.
        ///
        /// Note that only EBML version 1 exists at the time of writing.
        ebml_version: u8,
        /// The minimum version of EBML that needs to be supported in order to be able to read this document, as specified by the
        /// `EBMLReadVersion` element.
        ///
        /// Note that only EBML version 1 exists at the time of writing, so the document can only be read if this value equals `1`.
        ebml_read_version: u8,
        /// The maximum length of element IDs in octets, as specified by the `EBMLMaxIDLength` element.
        ///
        /// The default value is `4`. This reader only supports element ID lengths of 8 or below.
        ebml_max_id_length: u8,
        /// The maximum length of element element data size values in octets, as specified by the `EBMLMaxSizeLength` element (not to be
        /// confused with the maximum length of element data).
        ///
        /// The default value is `8`. This reader only supports element ID lengths of 8 or below.
        ebml_max_size_length: u8,
        /// The DocType of the document, as specified by the `DocType` element.
        ///
        /// The value is allocated memory owned by `EbmlDocument`.
        doctype: []const u8,
        /// The DocType version used for writing the document, as specified by the `DocTypeVersion` element.
        ///
        /// For example, the version in use for Matroska at the time of writing is `4`.
        doctype_version: u32,
        /// The minimum DocType version that needs to be supported in order to be able to read this document, as specified by the
        /// `DocTypeReadVersion` element.
        doctype_read_version: u32,
        /// A list of DocType extensions used in this document.
        ///
        /// The value is allocated memory owned by `EbmlDocument`.
        doctype_extensions: std.ArrayListUnmanaged(DoctypeExtension),

        /// Represents the current path of nested master elements in the document.
        path: [MAX_NESTING_DEPTH]MasterElementNestData,
        /// The length of [`path`], in elements. Only elements at indices `0` (inclusive) to `path_len` (exclusive) are valid.
        /// Elements beyond this slice must be treated as undefined memory.
        ///
        /// [`path`]: path
        path_len: u8,

        const Self = @This();

        /// Initializes a new `EbmlDocument`.
        ///
        /// The provided allocator is only used for runtime-sized data in the EBML header,
        /// not for anything in the EBML body.
        pub fn init(allocator: std.mem.Allocator, stream: *ReadWriteStream) std.mem.Allocator.Error!Self {
            return Self {
                .allocator = allocator,
                .stream = stream,

                .ebml_version = EBML_VERSION + 1, .ebml_read_version = EBML_VERSION + 1,
                .ebml_max_id_length = 4, .ebml_max_size_length = 8,
                .doctype = &.{},
                .doctype_version = std.math.maxInt(u32), .doctype_read_version = std.math.maxInt(u32),
                .doctype_extensions = try std.ArrayListUnmanaged(DoctypeExtension).initCapacity(allocator, 0),

                .path = .{undefined} ** MAX_NESTING_DEPTH,
                .path_len = 0,
            };
        }

        /// Deinitialize a given `EbmlDocument`. This specifically only deallocates the resources allocated by the [`init`] function,
        /// as well as anything from the EBML header. Currently, this only includes the DocType string, and memory for the list of
        /// DocType extensions with their respective names.
        ///
        /// [`init`]: init
        pub fn deinit(self: *Self) void {
            if (self.doctype.len != 0) {
                // DocType should be longer than 0 characters, so if len == 0, it hasn't been initialized yet
                self.allocator.free(self.doctype);
            }

            for (self.doctype_extensions.items) |extension| {
                self.allocator.free(extension.name);
            }

            self.doctype_extensions.deinit(self.allocator);
        }

        /// Reads an element ID.
        ///
        /// **Note**: This function does not check whether the ID is encoded in a valid way, or if an element with that ID even exists.
        pub inline fn readElementId(self: *Self) anyerror!ElementId {
            return primitive.readElementId(self.stream.any_reader());
        }

        /// Read a signed integer element.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readSignedInteger(self: *Self, default: ?i64) anyerror!i64 {
            return primitive.readSignedInteger(self.stream.any_reader(), default);
        }

        /// Read an unsigned integer element.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readUnsignedInteger(self: *Self, default: ?u64) anyerror!u64 {
            return primitive.readUnsignedInteger(self.stream.any_reader(), default);
        }

        /// Read a floating-point integer element.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readFloat(self: *Self, default: ?f64) anyerror!f64 {
            return primitive.readFloat(self.stream.any_reader(), default);
        }

        /// Reads the entire contents of a binary element into the specified buffer.
        ///
        /// If the buffer is not big enough to hold all of the element's data, `error.BufTooSmall` will be returned. In this case, the provided
        /// buffer as well as the current position in the stream will not be modified.
        ///
        /// If the element size is zero, the function will return without error and without modifying the provided buffer.
        /// This means that the buffer needs to be filled with the element's default value (usually all zeroes) before calling this.
        ///
        /// If the input stream unexpectedly ends before all bytes of the element have been read, `error.EndOfStream` will be returned.
        /// The provided buffer may be partially overwritten with the read data.
        ///
        /// Caller owns buffer memory.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readBinaryAllBuf(self: *Self, buffer: []u8) anyerror!void {
            return primitive.readBinaryAllBuf(self.stream.any_reader(), buffer);
        }

        /// Tries to read the entire contents of a binary element by allocating a buffer of the right size using the provided allocator.
        ///
        /// A maximum size has to be provided, as EBML allows binary elements to be practically unbounded in size. If the actual size of the
        /// element turns out to be greater than `max_size`, `error.BufTooSmall` will be returned.
        ///
        /// If the input stream unexpectedly ends before all bytes of the element have been read, `error.EndOfStream` will be returned.
        /// All data read as part of the binary element will be lost.
        ///
        /// If any error occurs during reading, such as an allocation failure or an IO error, all data read so far as part of the binary element
        /// will be lost. As the reader will now be positioned somewhere within the element with no indication of the number of bytes read,
        /// this state is not easily recoverable.
        ///
        /// Caller owns returned memory.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readBinaryAllAlloc(self: *Self, allocator: std.mem.Allocator, max_size: usize) anyerror![]u8 {
            return primitive.readBinaryAllAlloc(self.stream.any_reader(), allocator, max_size);
        }

        /// Read a binary element. This returns a [`BinaryElementReader`] that can be used to read the binary element's data.
        ///
        /// The returned reader is invalidated by any operation modifying the position of the reader provided to this method, such as using any
        /// of its read functions or seeking with a `SeekableStream`.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readBinary(self: *Self) anyerror!primitive.BinaryElementReader {
            return primitive.readBinary(self.stream.any_reader());
        }

        /// Read a date element.
        ///
        /// Date elements are defined in the EBML specification as follows:
        ///
        /// > The date element stores an integer in the same format as the signed
        /// > integer element that expresses a point in time referenced in
        /// > nanoseconds from the precise beginning of the third millennium of the
        /// > Gregorian Calendar in Coordinated Universal Time (also known as
        /// > 2001-01-01T00:00:00.000000000 UTC). This provides a possible
        /// > expression of time from September 1708 to April 2293.
        /// >
        /// > The integer stored represents the number of nanoseconds between the
        /// > date to express and 2001-01-01T00:00:00.000000000 UTC, not counting
        /// > leap seconds. That is 86,400,000,000,000 nanoseconds for each day.
        /// > Conversions from other date systems should ensure leap seconds are
        /// > not counted in EBML values.
        /// >
        /// > The 2001-01-01T00:00:00.000000000 UTC date also corresponds to
        /// > 978307200 seconds in Unix time.
        ///
        /// This function is exactly equivalent to [`readSignedInteger`], except that it only allows element sizes of `0` and `8`.
        /// You can use `readSignedInteger` instead, which allows any element size between 0 and 8 (inclusive), if you want to be more
        /// lenient in parsing dates.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        ///
        /// [`readSignedInteger`]: readSignedInteger
        pub fn readDate(self: *Self, default: ?i64) anyerror!i64 {
            return primitive.readBinary(self.stream.any_reader(), default);
        }

        /// Read a master element.
        ///
        /// // TODO Add documentation
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn readMaster(self: *Self, id: ElementId) anyerror!void {
            if (self.path_len == MAX_NESTING_DEPTH - 1) {
                return error.NestingTooDeep;
            }

            const size = try primitive.readElementDataSize(self.stream.any_reader());
            std.debug.print("Element data size: {d}\n", .{size});

            self.path[self.path_len] = MasterElementNestData { .id = id, .end_pos = self.stream.getPos() + size, };
            self.path_len += 1;
        }

        /// Skip an element.
        ///
        /// This function requires the element ID to have been read already, i. e. the input stream position must be on the element size value
        /// of the element. If this function suceeds, the input stream will be positioned on the start (element ID value) of the next element or
        /// the end of the stream. If it fails, the stream position may end up anywhere within the element.
        pub fn skipElement(self: *Self) anyerror!void {
            const size = try primitive.readElementDataSize(self.stream.any_reader());
            try self.stream.seekBy(@intCast(size));
        }

        pub fn trimPath(self: *Self) void {
            const pos = self.stream.getPos();
            var i: u8 = 0;

            while (i != self.path_len) {
                // Reverse order. Should be safe, as:
                //      i != path_len
                //   -> i <  path_len
                //   -> (path_len - i) >= 1
                //   -> (path_len - i) - 1 >= 0
                const j = self.path_len - i - 1;

                const data = self.path[j];
                i += 1;

                if (data.end_pos <= pos) {
                    self.path_len = j;
                    i = 0;
                }
            }
        }

        /// Read the EBML header.
        ///
        /// If the header is not found or is not correct, `error.InvalidHeader` will be returned.
        pub fn readHeader(self: *Self) anyerror!void {
            std.debug.assert(0 == self.path_len);

            const ebml_id = try self.readElementId();

            if (ebml_id.id != matroska.ID_EBML) {
                return error.InvalidHeader;
            }

            // \EBML
            try self.readMaster(ebml_id);
            self.trimPath();

            while (self.path_len != 0) {
                const id = try self.readElementId();

                switch (id.id) {
                    // TODO
                    else => {
                        log.warn("Skipping unknown element (ID 0x{X})", .{id.id});
                        try self.skipElement();
                    },
                }

                self.trimPath();
            }
        }
    };
}

test "EbmlDocument on Matroska test file" {
    // Tests are run relative to the project directory, apparently
    const file = try std.fs.cwd().openFile("./test/test1.mkv", .{});
    defer file.close();

    var stream = io.streamFromFile(file);
    var document = try EbmlDocument(@TypeOf(stream)).init(std.testing.allocator, &stream);

    try document.readHeader();
}
