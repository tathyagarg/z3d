const std = @import("std");
const assert = std.debug.assert;
const File = std.fs.File;

const utils = @import("utils.zig");
const Dimensions = utils.Dimensions;

const RGB = @import("../graphics/rgb.zig").RGB;
const Vec2 = @import("../../core/math/math.zig").Vec2;
const float = @import("../../core/constants.zig").FLOAT;
const Vec2f = Vec2(float);

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

pub const FilterType = enum(u8) {
    None = 0,
    Sub = 1,
    Up = 2,
    Average = 3,
    Paeth = 4,
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

pub fn get_palette_data(chunk_length: usize, chunk_data: []const u8, palette_data: *[]RGB) !void {
    const palette_length = @divExact(chunk_length, 3);

    for (0..palette_length - 1) |i| {
        palette_data.*[i] = RGB{
            .r = chunk_data[i * 3 + 0],
            .g = chunk_data[i * 3 + 1],
            .b = chunk_data[i * 3 + 2],
        };
    }
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

    if (std.mem.eql(u8, &chunk_type, "IHDR")) {
        const dims = get_dimensions(chunk_data);
        const width = dims.width;
        const height = dims.height;
        const color_type = get_color_type(chunk_data);

        image_data.width = width;
        image_data.height = height;
        image_data.color_type = color_type;
        image_data.bit_depth = chunk_data[8];

        return true;
    } else if (std.mem.eql(u8, &chunk_type, "PLTE")) {
        var palette = try std.heap.page_allocator.alloc(RGB, PLTE_MAX_ENTRIES);
        try get_palette_data(chunk_length, chunk_data, &palette);
        image_data.palette = palette;

        return true;
    } else if (std.mem.eql(u8, &chunk_type, "IDAT")) {
        var reader = std.io.fixedBufferStream(chunk_data);
        var temporary = std.ArrayList(u8).init(std.heap.page_allocator);
        defer temporary.deinit();

        try std.compress.zlib.decompress(reader.reader(), &temporary.writer());

        // const samples_per_byte = @divExact(8, image_data.bit_depth);
        var samples_per_scanline = image_data.width;
        const sample_per_pixel = get_samples_per_pixel(image_data.color_type);

        samples_per_scanline *= sample_per_pixel;
        const bytes_per_pixel =
            @divFloor(image_data.bit_depth * sample_per_pixel, 8) +
            @intFromBool(image_data.bit_depth * sample_per_pixel % 8 != 0);

        const scanline_length =
            1 + image_data.width * bytes_per_pixel +
            @intFromBool(image_data.width * image_data.bit_depth % 8 != 0);

        // const mask: u8 = @intCast((@as(u256, 1) << image_data.bit_depth) - 1);
        var decoded = std.ArrayList(u8).init(std.heap.page_allocator);
        defer decoded.deinit();

        for (0..image_data.height) |y| {
            const filter_type = temporary.items[y * scanline_length];
            for (1..scanline_length) |x| {
                const prev = if (x <= bytes_per_pixel) 0 else decoded.items[y * scanline_length + x - bytes_per_pixel - 1 - y];
                const prior = if (y == 0) 0 else decoded.items[(y - 1) * scanline_length + x - y];
                const prev_prior = if (x <= bytes_per_pixel or y == 0) 0 else decoded.items[(y - 1) * scanline_length + x - bytes_per_pixel - 1];

                const target = temporary.items[y * scanline_length + x];
                const byte = get_byte(@enumFromInt(filter_type), target, prev, prior, prev_prior);
                try decoded.append(byte);
            }
        }

        if (image_data.bit_depth != 8) {
            std.debug.print("Unsupported bit depth: {d}\n", .{image_data.bit_depth});
            return error.UnsupportedBitDepth;
        }

        switch (image_data.color_type) {
            .GrayScale => for (decoded.items) |byte|
                try image_data.pixel_data.append(RGB{ .r = byte, .g = byte, .b = byte }),

            .TrueColor => {
                for (0..@divExact(decoded.items.len, 3)) |i| {
                    const r = decoded.items[i * 3 + 0];
                    const g = decoded.items[i * 3 + 1];
                    const b = decoded.items[i * 3 + 2];

                    try image_data.pixel_data.append(RGB{ .r = r, .g = g, .b = b });
                }
            },

            .IndexedColor => {
                for (decoded.items) |byte| {
                    const color = image_data.palette.?[byte];
                    try image_data.pixel_data.append(color);
                }
            },

            .GrayScaleAlpha => {
                for (0..@divExact(decoded.items.len, 2)) |i| {
                    const gray = decoded.items[i * 2 + 0];
                    // Ingore alpha channel

                    try image_data.pixel_data.append(RGB{ .r = gray, .g = gray, .b = gray });
                }
            },

            .TrueColorAlpha => {
                for (0..@divExact(decoded.items.len, 4)) |i| {
                    const r = decoded.items[i * 4 + 0];
                    const g = decoded.items[i * 4 + 1];
                    const b = decoded.items[i * 4 + 2];
                    // Ingore alpha channel

                    try image_data.pixel_data.append(RGB{ .r = r, .g = g, .b = b });
                }
            },

            else => unreachable,
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

/// Decodes the byte from the given filter type, with the format:
/// +---+---+
/// | A | B |
/// +---+---+
/// | C | X |
/// +---+---+
/// A = prev_prior
/// B = prior
/// C = prev
/// X = target
pub fn get_byte(filter_type: FilterType, target: u8, prev: u8, prior: u8, prev_prior: u8) u8 {
    return switch (filter_type) {
        .None => target,
        .Sub => @intCast((@as(u9, target) + @as(u9, prev)) % 256),
        .Up => @intCast((@as(u9, target) + @as(u9, prior)) % 256),
        .Average => target + @divFloor(prev + prior, 2),
        .Paeth => @intCast((@as(u9, target) + @as(u9, paeth_predictor(prev, prior, prev_prior))) % 256),
    };
}

pub fn get_samples_per_pixel(color_type: ColorType) u8 {
    return switch (color_type) {
        ColorType.GrayScale => 1,
        ColorType.TrueColor => 3,
        ColorType.IndexedColor => 1,
        ColorType.GrayScaleAlpha => 2,
        ColorType.TrueColorAlpha => 4,
        else => unreachable,
    };
}

pub fn paeth_predictor(a: u8, b: u8, c: u8) u8 {
    const p = @as(i16, a) + @as(i16, b) - @as(i16, c);
    const pa = @abs(p - a);
    const pb = @abs(p - b);
    const pc = @abs(p - c);

    return if (pa <= pb and pa <= pc)
        a
    else if (pb <= pc)
        b
    else
        c;
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

    pub fn sample(self: Self, uv: Vec2f) RGB {
        const x: usize = @intFromFloat(uv.x * (@as(float, @floatFromInt(self.width)) - 1));
        const y: usize = @intFromFloat(uv.y * (@as(float, @floatFromInt(self.height)) - 1));

        const pixel = self.pixel_data.items[y * self.width + x];
        return pixel;
    }
};
