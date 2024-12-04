// This is a program to convert the points in a 3D .obj file (assets/xtree.obj) to a .svg file
const z3d = @import("z3d");
const std = @import("std");
const utils = @import("utils.zig");

const _Mat4 = z3d.math.Mat4;

const line_string = utils.LINE_STRING;
const allocator = std.testing.allocator;
const Mat4 = _Mat4(utils.VERTEX_TYPE);

const computation_constants = .{
    .canvas_width = 2,
    .canvas_height = 2,
    .screen_width = 512,
    .screen_height = 512,
};

test "compute pixel coordinates" {
    const obj_data = try utils.fetch_data("xtree.obj", allocator);
    const vertices = obj_data.vertices;
    const faces = obj_data.faces;

    defer vertices.deinit();
    defer faces.deinit();

    var outputs = try std.fs.cwd().openDir("tests/outputs", .{});
    defer outputs.close();

    const svg = try outputs.createFile("xtree.svg", .{});
    defer svg.close();

    _ = try svg.write("<svg version=\"1.1\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\" height=\"512\" width=\"512\">");

    const camera_to_world = Mat4.from([4][4]f32{
        .{ 0.871214, 0, -0.490904, 0 },
        .{ -0.192902, 0.919559, -0.342346, 0 },
        .{ 0.451415, 0.392953, 0.801132, 0 },
        .{ 14.777467, 29.361945, 27.993464, 1 },
    });
    const world_to_camera = camera_to_world.inverse();

    for (faces.items) |face| {
        const v0world = vertices.items[face.x];
        const v1world = vertices.items[face.y];
        const v2world = vertices.items[face.z];

        const v0raster = try v0world.compute_pixel_coords(
            world_to_camera,
            computation_constants,
        );
        const v1raster = try v1world.compute_pixel_coords(
            world_to_camera,
            computation_constants,
        );
        const v2raster = try v2world.compute_pixel_coords(
            world_to_camera,
            computation_constants,
        );

        const v01 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v0raster.x, v0raster.y, v1raster.x, v1raster.y },
        );
        defer std.testing.allocator.free(v01);

        const v12 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v1raster.x, v1raster.y, v2raster.x, v2raster.y },
        );
        defer std.testing.allocator.free(v12);

        const v02 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v0raster.x, v0raster.y, v2raster.x, v2raster.y },
        );
        defer std.testing.allocator.free(v02);

        _ = try svg.write(v01);
        _ = try svg.write(v12);
        _ = try svg.write(v02);
    }

    _ = try svg.write("</svg>\n");
}
