const std = @import("std");
const z3d = @import("z3d");

const ArrayList = std.ArrayList;

pub const Vec3 = z3d.math.Vec3;

pub const LINE_STRING = "<line x1=\"{d}\" y1=\"{d}\" x2=\"{d}\" y2=\"{d}\" style=\"stroke:rgb({d}, 0, 0); stroke-width: 1\" />\n";

pub const ASSETS_DIR = "assets";
pub const MAX_LINE_LEN: usize = 64;
pub const VERTEX_TYPE: type = f32;

pub const Vec3Vertex = Vec3(VERTEX_TYPE);

pub fn fetch_data(
    source_file: []const u8,
    allocator: std.mem.Allocator,
) !struct {
    vertices: ArrayList(Vec3Vertex),
    faces: ArrayList(Vec3(usize)),
} {
    var vertices = ArrayList(Vec3Vertex).init(allocator);
    var faces = ArrayList(Vec3(usize)).init(allocator);

    var assets_dir = try std.fs.cwd().openDir(ASSETS_DIR, .{});
    defer assets_dir.close();

    const obj_file = try assets_dir.openFile(source_file, .{});
    defer obj_file.close();

    var buffer: [MAX_LINE_LEN]u8 = undefined;
    while (true) {
        // 10 = \n = Newline as delimiter between lines.
        // Exit the loop when reading a newline throws an error (EOF)
        _ = obj_file.reader().readUntilDelimiter(buffer[0..MAX_LINE_LEN], 10) catch break;

        var line_iterator = std.mem.splitScalar(u8, buffer[2..MAX_LINE_LEN], 32); // 32 = space

        if (buffer[0] == 'v') {
            // Handle vertex
            const x = try std.fmt.parseFloat(VERTEX_TYPE, line_iterator.next().?);
            const y = try std.fmt.parseFloat(VERTEX_TYPE, line_iterator.next().?);
            const z = try std.fmt.parseFloat(VERTEX_TYPE, line_iterator.next().?);

            try vertices.append(Vec3Vertex.init(x, y, z));
        } else if (buffer[0] == 'f') {
            // Handle face
            const x = try std.fmt.parseInt(usize, line_iterator.next().?, 0);
            const y = try std.fmt.parseInt(usize, line_iterator.next().?, 0);
            const z = try std.fmt.parseInt(usize, line_iterator.next().?, 0);

            // Subtract 1 from all to turn them into 0-indexed values that can be used to easily index the vertices arraylist.
            try faces.append(Vec3(usize).init(x - 1, y - 1, z - 1));
        } else {
            unreachable;
        }
    }

    return .{ .vertices = vertices, .faces = faces };
}
