const z3d = @import("z3d");
const std = @import("std");
const utils = @import("utils.zig");

const _Mat4 = z3d.math.Mat4;

const line_string = utils.LINE_STRING;
const allocator = std.testing.allocator;
const Mat4 = _Mat4(utils.VERTEX_TYPE);

const focal_length = 55; // in mm
const film_aperture_width = 0.825; // in in.
const film_aperture_height = 0.446; // in in.

const near_clipping = 0.1;
const far_clipping = 1_000;

const film_fit = z3d.graphics.FitResolutionGate.kOverscan;

const SCREEN_HEIGHT = 512;
const SCREEN_WIDTH = 512;

test "pinhole camera" {
    const obj_data = try utils.fetch_data("boat.obj", allocator);
    const vertices = obj_data.vertices;
    const faces = obj_data.faces;

    defer vertices.deinit();
    defer faces.deinit();

    const film_aspect_ratio = film_aperture_width / film_aperture_height;
    const device_aspect_ratio = @as(f32, @floatFromInt(SCREEN_WIDTH)) /
        @as(f32, @floatFromInt(SCREEN_HEIGHT));

    var top = @as(f32, @floatCast((film_aperture_height * (z3d.math.INCH_TO_MM / @as(f64, @floatFromInt(2)))) / focal_length * near_clipping));
    var right = @as(f32, @floatCast((film_aperture_width * (z3d.math.INCH_TO_MM / @as(f64, @floatFromInt(2)))) / focal_length * near_clipping));

    var xscale: f32 = 1;
    var yscale: f32 = 1;

    switch (film_fit) {
        .kFill => {
            if (film_aspect_ratio > device_aspect_ratio) {
                xscale = device_aspect_ratio / film_aspect_ratio;
            } else {
                yscale = film_aspect_ratio / device_aspect_ratio;
            }
        },
        .kOverscan => {
            if (film_aspect_ratio > device_aspect_ratio) {
                yscale = film_aspect_ratio / device_aspect_ratio;
            } else {
                xscale = device_aspect_ratio / film_aspect_ratio;
            }
        },
    }

    right *= xscale;
    top *= yscale;

    const bottom = -top;
    const left = -right;

    const computation_consts = z3d.math.PixelComputationOptions{
        .bottom = bottom,
        .left = left,
        .top = top,
        .right = right,
        .near = near_clipping,
        .screen_width = SCREEN_WIDTH,
        .screen_height = SCREEN_HEIGHT,
    };

    var outputs = try std.fs.cwd().openDir("tests/outputs", .{});
    defer outputs.close();

    const svg = try outputs.createFile("boat.svg", .{});
    defer svg.close();

    _ = try svg.write("<svg version=\"1.1\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\" height=\"512\" width=\"512\">");

    const camera_to_world = Mat4.from([4][4]utils.VERTEX_TYPE{
        .{ -0.95424, 0, 0.299041, 0 },
        .{ 0.0861242, 0.95763, 0.274823, 0 },
        .{ -0.28637, 0.288002, -0.913809, 0 },
        .{ -3.734612, 7.610426, -14.152769, 1 },
    });
    const world_to_camera = camera_to_world.inverse();

    for (faces.items) |face| {
        const v0world = vertices.items[face.x];
        const v1world = vertices.items[face.y];
        const v2world = vertices.items[face.z];

        const v0raster_res = try v0world.compute_pixel_coords(world_to_camera, computation_consts);
        const v1raster_res = try v1world.compute_pixel_coords(world_to_camera, computation_consts);
        const v2raster_res = try v2world.compute_pixel_coords(world_to_camera, computation_consts);

        const visible = v0raster_res.visible and v1raster_res.visible and v2raster_res.visible;
        const v0raster = v0raster_res.raster;
        const v1raster = v1raster_res.raster;
        const v2raster = v2raster_res.raster;

        const visibility_color = @as(u8, @intFromBool(!visible)) * 255;

        const v01 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v0raster.x, v0raster.y, v1raster.x, v1raster.y, visibility_color },
        );
        defer std.testing.allocator.free(v01);

        const v12 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v1raster.x, v1raster.y, v2raster.x, v2raster.y, visibility_color },
        );
        defer std.testing.allocator.free(v12);

        const v02 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v0raster.x, v0raster.y, v2raster.x, v2raster.y, visibility_color },
        );
        defer std.testing.allocator.free(v02);

        _ = try svg.write(v01);
        _ = try svg.write(v12);
        _ = try svg.write(v02);
    }

    _ = try svg.write("</svg>\n");
}
