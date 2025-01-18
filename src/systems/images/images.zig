const std = @import("std");
const png = @import("png.zig");
const utils = @import("utils.zig");

const math = @import("../../core/math/math.zig");
const constants = @import("../../core/constants.zig");
const Vec2 = math.Vec2;

const Vec2f = Vec2(constants.FLOAT);

const RGB = @import("../graphics/graphics.zig").RGB;

// const ImageData = utils.ImageData;

pub const FileData = union(enum) {
    PNG: png.ImageData,
    JPEG: u1,
    BMP: u1,
};

pub const Image = struct {
    file_path: []const u8,
    file_buffer: std.fs.File,

    file_type: FileData = undefined,

    bit_depth: u8 = undefined,
    color_type: u8 = undefined,

    pixels: []u8 = undefined,

    const Self = @This();

    pub fn init(fpath: []const u8) !Self {
        var image = Self{
            .file_path = fpath,
            .file_buffer = try std.fs.cwd().openFile(fpath, .{}),
        };
        try image.get_filedata();

        return image;
    }

    pub fn deinit(self: *Self) void {
        self.file_buffer.close();
        switch (self.file_type) {
            FileData.PNG => self.file_type.PNG.deinit(),
            else => {},
        }
    }

    pub fn get_filedata(self: *Self) !void {
        var ext_iter = std.mem.splitScalar(u8, self.file_path, '.');
        var ext: []const u8 = undefined;

        while (ext_iter.next()) |ext_slice| {
            ext = ext_slice;
        }

        const ext_len = ext.len;
        const ext_str = ext[0..ext_len];

        self.file_type = if (std.mem.eql(u8, ext_str, "png"))
            FileData{ .PNG = try png.get_image_data(self.file_buffer) }
        else if (std.mem.eql(u8, ext_str, "jpeg") or std.mem.eql(u8, ext_str, "jpg"))
            FileData{ .JPEG = 0 }
        else if (std.mem.eql(u8, ext_str, "bmp"))
            FileData{ .BMP = 0 }
        else
            unreachable;
    }

    pub fn sample(self: Self, uv: Vec2f) RGB {
        return switch (self.file_type) {
            FileData.PNG => |img_data| img_data.sample(uv),
            else => RGB{ .r = 0, .g = 0, .b = 0 },
        };
    }
};
