const std = @import("std");
const z3d = @import("z3d");

const ArrayList = std.ArrayList;

pub const Vec3 = z3d.math.Vec3;
pub const Vec2 = z3d.math.Vec2;

pub const LINE_STRING = "<line x1=\"{d}\" y1=\"{d}\" x2=\"{d}\" y2=\"{d}\" style=\"stroke:rgb({d}, 0, 0); stroke-width: 1\" />\n";

pub const ASSETS_DIR = "tests/assets";
pub const MAX_LINE_LEN: usize = 64;
pub const VERTEX_TYPE: type = f32;
pub const TEXTURE_TYPE: type = f32;

pub const Vec3Vertex = Vec3(VERTEX_TYPE);
pub const Vec2Texture = Vec2(TEXTURE_TYPE);

pub const IgnoreOptions = packed struct {
    v: bool = false,
    vn: bool = false,
    vt: bool = false,
    f: bool = false,
};

pub fn fetch_data(
    source_file: []const u8,
    allocator: std.mem.Allocator,
    ignore: IgnoreOptions,
) !struct {
    vertices: ArrayList(Vec3Vertex),
    faces: ArrayList(Vec3(usize)),
    textures: ArrayList(Vec2Texture),
    face_textures: ArrayList(Vec3(usize)),
} {
    var vertices = ArrayList(Vec3Vertex).init(allocator);
    var faces = ArrayList(Vec3(usize)).init(allocator);
    var textures = ArrayList(Vec2Texture).init(allocator);
    var face_textures = ArrayList(Vec3(usize)).init(allocator);

    var assets_dir = try std.fs.cwd().openDir(ASSETS_DIR, .{});
    defer assets_dir.close();

    const obj_file = try assets_dir.openFile(source_file, .{});
    defer obj_file.close();

    var i: i32 = 0;
    var buffer: [MAX_LINE_LEN]u8 = undefined;
    while (true) : (i += 1) {
        // 10 = \n = Newline as delimiter between lines.
        // Exit the loop when reading a newline throws an error (EOF)
        _ = obj_file.reader().readUntilDelimiter(buffer[0..MAX_LINE_LEN], 10) catch break;

        var line_iterator = std.mem.splitScalar(u8, buffer[0..MAX_LINE_LEN], 32); // 32 = space
        const line_type = line_iterator.next().?;

        if (std.mem.eql(u8, line_type, "v") and !ignore.v) {
            // Handle vertex
            const x = try std.fmt.parseFloat(VERTEX_TYPE, line_iterator.next().?);
            const y = try std.fmt.parseFloat(VERTEX_TYPE, line_iterator.next().?);
            const z = try std.fmt.parseFloat(VERTEX_TYPE, line_iterator.next().?);

            try vertices.append(Vec3Vertex.init(x, y, z));
        } else if (std.mem.eql(u8, line_type, "f") and !ignore.f) {
            // Handle face
            // 47 stands for /
            var pre_x = std.mem.splitScalar(u8, line_iterator.next().?, 47);
            var pre_y = std.mem.splitScalar(u8, line_iterator.next().?, 47);
            var pre_z = std.mem.splitScalar(u8, line_iterator.next().?, 47);

            const x = try std.fmt.parseInt(usize, pre_x.next().?, 0);
            const y = try std.fmt.parseInt(usize, pre_y.next().?, 0);
            const z = try std.fmt.parseInt(usize, pre_z.next().?, 0);

            const xt = try std.fmt.parseInt(usize, pre_x.next().?, 0);
            const yt = try std.fmt.parseInt(usize, pre_y.next().?, 0);
            const zt = try std.fmt.parseInt(usize, pre_z.next().?, 0);

            // Subtract 1 from all to turn them into 0-indexed values that can be used to easily index the vertices arraylist.
            try faces.append(Vec3(usize).init(x - 1, y - 1, z - 1));
            try face_textures.append(Vec3(usize).init(xt - 1, yt - 1, zt - 1));
        } else if (std.mem.eql(u8, line_type, "vt") and !ignore.vt) {
            const u = try std.fmt.parseFloat(TEXTURE_TYPE, line_iterator.next().?);
            const v = try std.fmt.parseFloat(TEXTURE_TYPE, line_iterator.next().?);

            try textures.append(Vec2Texture.init(u, v));
        }
    }

    return .{ .vertices = vertices, .faces = faces, .textures = textures, .face_textures = face_textures };
}
