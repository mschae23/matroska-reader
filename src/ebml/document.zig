const std = @import("std");

const log = std.log.scoped(.ebml);

const io = @import("../io.zig");
const primitive = @import("./primitive.zig");

const EbmlError = primitive.EbmlError;

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
    // TODO Is this possible, like using `anytype`?
    return struct {
        allocator: std.mem.Allocator,
        stream: *ReadWriteStream,

        ebml_version: u8, ebml_read_version: u8, // There only exists EBML version 1 at the time of writing
        ebml_max_id_length: u8, // 4 by default, this reader only supports length <=8
        ebml_max_size_length: u8, // 8 by default, this reader only supports length <=8
        doctype: []const u8, // DocType, owned by EbmlDocument
        doctype_version: u32, doctype_read_version: u32, // DocType version (for example, 4 for Matroska at the time of writing)
        doctype_extensions: std.ArrayListUnmanaged(DoctypeExtension), // Owned by EbmlDocument

        path: [MAX_NESTING_DEPTH]MasterElementNestData,
        path_len: u8,

        const Self = @This();

        /// Initializes a new EbmlDocument.
        ///
        /// `seeker` is required to be the `SeekableStream` for `reader`.
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

        pub fn readMaster(document: *Self, id: ElementId) anyerror!void {
            const size = try primitive.readElementDataSize(document.stream.reader());
            _ = size;

            if (document.path_len == MAX_NESTING_DEPTH - 1) {
                return error.NestingTooDeep;
            }

            document.path[document.path_len] == .{ .id = id, .end_pos = undefined, }; // TODO How to determine end pos?
            document.path_len += 1;
            // TODO
        }
    };
}

const matroska = @import("../matroska_id_table.zig");

test "EbmlDocument on Matroska test file" {
    // Tests are run relative to the project directory, apparently
    const file = try std.fs.cwd().openFile("./test/test1.mkv", .{});
    defer file.close();

    var stream = io.streamFromFile(file);
    var document = try EbmlDocument(@TypeOf(stream)).init(std.testing.allocator, &stream);

    std.debug.print("Element ID: {x}\n", .{(try document.readElementId()).id});
}
