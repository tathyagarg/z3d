const std = @import("std");
const assert = std.debug.assert;
const File = std.fs.File;

const utils = @import("utils.zig");
const Dimensions = utils.Dimensions;

const RGB = @import("../graphics/rgb.zig").RGB;

const SIGNATURE_LENGTH = 8;
const SIGNATURE: []const u8 = &[8]u8{ 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A };

const CHUNK_LENGTH_HEADER_LENGTH = 4;
const CHUNK_TYPE_HEADER_LENGTH = 4;
const CHUNK_CRC_HEADER_LENGTH = 4;

const IHDR_LENGTH = 13;
const GAMA_LENGTH = 4;

const CT_GRAYSCALE = 0;
const CT_PALETTE_USED = 1 << 0;
const CT_COLOR_USED = 1 << 1;
const CT_ALPHA_USED = 1 << 2;

const PLTE_MAX_ENTRIES = 256;

pub const ColorType = enum(u8) {
    GrayScale = CT_GRAYSCALE,
    Undefined = CT_PALETTE_USED,
    TrueColor = CT_COLOR_USED,
    IndexedColor = CT_PALETTE_USED | CT_COLOR_USED,
    GrayScaleAlpha = CT_GRAYSCALE | CT_ALPHA_USED,
    TrueColorAlpha = CT_COLOR_USED | CT_ALPHA_USED,
};

pub fn get_total_chunk_length(data: usize) i64 {
    return @as(i64, @intCast(CHUNK_LENGTH_HEADER_LENGTH + CHUNK_TYPE_HEADER_LENGTH + data + CHUNK_CRC_HEADER_LENGTH));
}

pub fn get_chunk_length(file_buffer: File) !usize {
    var chunk_length_buf: [CHUNK_LENGTH_HEADER_LENGTH]u8 = undefined;
    const bytes_read: usize = try file_buffer.read(&chunk_length_buf);
    assert(bytes_read == CHUNK_LENGTH_HEADER_LENGTH);

    return @as(usize, chunk_length_buf[0]) << 24 |
        @as(usize, chunk_length_buf[1]) << 16 |
        @as(usize, chunk_length_buf[2]) << 8 |
        @as(usize, chunk_length_buf[3]);
}

pub fn verify_signature(file_buffer: File) !void {
    var bytes_read: usize = undefined;
    var signature_buffer: [SIGNATURE_LENGTH]u8 = undefined;

    try file_buffer.seekTo(0);
    bytes_read = try file_buffer.read(&signature_buffer);

    assert(bytes_read == SIGNATURE_LENGTH);
    assert(std.mem.eql(u8, &signature_buffer, SIGNATURE));
}

pub fn skip_crc(file_buffer: File) !void {
    try file_buffer.seekBy(CHUNK_CRC_HEADER_LENGTH);
}

pub fn get_dimensions(ihdr: []u8) Dimensions {
    const width: u32 = @as(u32, ihdr[0]) << 24 |
        @as(u32, ihdr[1]) << 16 |
        @as(u32, ihdr[2]) << 8 |
        @as(u32, ihdr[3]);

    const height: u32 = @as(u32, ihdr[4]) << 24 |
        @as(u32, ihdr[5]) << 16 |
        @as(u32, ihdr[6]) << 8 |
        @as(u32, ihdr[7]);

    return Dimensions{ .width = width, .height = height };
}

pub fn get_color_type(ihdr: []u8) ColorType {
    const color_type: u8 = ihdr[9];

    return switch (color_type) {
        CT_GRAYSCALE => ColorType.GrayScale,
        CT_COLOR_USED => ColorType.TrueColor,
        (CT_PALETTE_USED | CT_COLOR_USED) => ColorType.IndexedColor,
        (CT_GRAYSCALE | CT_ALPHA_USED) => ColorType.GrayScaleAlpha,
        (CT_COLOR_USED | CT_ALPHA_USED) => ColorType.TrueColorAlpha,
        else => unreachable,
    };
}

pub fn check_gama_presence(file_buffer: File) !bool {
    const chunk_length = try get_chunk_length(file_buffer);

    if (chunk_length != GAMA_LENGTH) {
        try file_buffer.seekBy(-CHUNK_LENGTH_HEADER_LENGTH);
        return false;
    }

    var chunk_type_buf: [CHUNK_TYPE_HEADER_LENGTH]u8 = undefined;
    const bytes_read = try file_buffer.read(&chunk_type_buf);
    assert(bytes_read == CHUNK_TYPE_HEADER_LENGTH);

    try file_buffer.seekBy(-CHUNK_LENGTH_HEADER_LENGTH - CHUNK_TYPE_HEADER_LENGTH);
    if (!std.mem.eql(u8, &chunk_type_buf, "gAMA")) {
        return false;
    }

    return true;
}

pub fn get_palette_data(chunk_length: usize, chunk_data: []const u8) ![]RGB {
    const palette_length = @divExact(chunk_length, 3);

    var palette_data: [PLTE_MAX_ENTRIES]RGB = undefined;
    for (0..palette_length - 1) |i| {
        palette_data[i] = RGB{
            .r = chunk_data[i * 3 + 0],
            .g = chunk_data[i * 3 + 1],
            .b = chunk_data[i * 3 + 2],
        };
    }

    return palette_data[0..palette_length];
}

pub fn get_chunk_type(file_buffer: File, buffer: *[CHUNK_TYPE_HEADER_LENGTH]u8) !void {
    const bytes_read = try file_buffer.read(buffer);
    assert(bytes_read == CHUNK_TYPE_HEADER_LENGTH);
}

pub fn get_chunk_data(file_buffer: File, chunk_length: usize) ![]u8 {
    const chunk_data: []u8 = try std.heap.page_allocator.alloc(u8, chunk_length);
    const bytes_read = try file_buffer.read(chunk_data);
    assert(bytes_read == chunk_length);

    return chunk_data;
}

pub fn parse_chunk(file_buffer: File, image_data: *ImageData) !bool {
    var chunk_type: [CHUNK_TYPE_HEADER_LENGTH]u8 = undefined;

    const chunk_length = try get_chunk_length(file_buffer);
    try get_chunk_type(file_buffer, &chunk_type);
    const chunk_data = try get_chunk_data(file_buffer, chunk_length);

    std.debug.print("Chunk Type: {s}\n", .{chunk_type});

    if (std.mem.eql(u8, &chunk_type, "IHDR")) {
        const dims = get_dimensions(chunk_data);
        const width = dims.width;
        const height = dims.height;
        const color_type = get_color_type(chunk_data);

        image_data.width = width;
        image_data.height = height;
        image_data.color_type = color_type;

        return true;
    } else if (std.mem.eql(u8, &chunk_type, "PLTE")) {
        const palette = try get_palette_data(chunk_length, chunk_data);

        image_data.palette = palette;

        return true;
    } else if (std.mem.eql(u8, &chunk_type, "IDAT")) {
        var reader = std.io.fixedBufferStream(chunk_data);
        var temporary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer temporary.deinit();

        try std.compress.zlib.decompress(reader.reader(), &temporary.writer());

        const useless_bits = image_data.bit_depth * image_data.width % 8;
        for (0..image_data.height) |y| {
            const byte_count = @divFloor(image_data.width * image_data.bit_depth, 8) + (useless_bits != 0);
            for (temporary.items[y * image_data.width + 1 .. (y + 1) * image_data.width]) |x| {
                // TODO: Implement this
            }
        }

        return true;
    } else if (std.mem.eql(u8, &chunk_type, "gAMA")) {
        return true;
    } else if (std.mem.eql(u8, &chunk_type, "IEND")) {
        return false;
    } else if (std.mem.eql(u8, &chunk_type, "sRGB")) {
        return true;
    } else if (std.mem.eql(u8, &chunk_type, "pHYs")) {
        return true;
    } else if (std.mem.eql(u8, &chunk_type, "tRNS")) {
        image_data.transparency = chunk_data;
        return true;
    }

    return false;
}

pub fn get_image_data(file_buffer: File) !ImageData {
    try verify_signature(file_buffer);

    var image_data = try ImageData.init();
    while (try parse_chunk(file_buffer, &image_data)) : (try skip_crc(file_buffer)) {}

    return image_data;
}

pub const ImageData = struct {
    width: usize = 0,
    height: usize = 0,
    color_type: ColorType = .Undefined,
    bit_depth: u8 = 0,
    palette: ?[]RGB = null,
    transparency: ?[]u8 = null,

    pixel_data: std.ArrayList(RGB),

    const Self = @This();

    pub fn init() !Self {
        return Self{
            .pixel_data = std.ArrayList(RGB).init(std.heap.page_allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        self.pixel_data.deinit();
    }
};
