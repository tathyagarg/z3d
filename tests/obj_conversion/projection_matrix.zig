const z3d = @import("z3d");
const std = @import("std");
const utils = @import("utils.zig");

const _Mat4 = z3d.math.Mat4;
const Vec3Vertex = utils.Vec3Vertex;
const Vec2Texture = utils.Vec2Texture;

const allocator = std.testing.allocator;
const Mat4 = _Mat4(utils.VERTEX_TYPE);
const RGB = z3d.graphics.types.RGB;

const focal_length = 20; // in mm
const film_aperture_width = 0.980; // in in.
const film_aperture_height = 0.735; // in in.

const near_clipping = 1;
const far_clipping = 1_000;

const film_fit = z3d.graphics.FitResolutionGate.kOverscan;

const SCREEN_HEIGHT: usize = 512;
const SCREEN_WIDTH: usize = 512;

const angle_of_view = 90;
const near = 0.1;
const far = 100;

test "projection matrix" {
    var world_to_camera = Mat4.identity();
    world_to_camera.m[3][1] = -10;
    world_to_camera.m[3][2] = -20;

    const projection_matrix = z3d.graphics.projection_matrix_factory(angle_of_view, near, far)();
    var buffer: [SCREEN_WIDTH * SCREEN_HEIGHT]u8 = undefined;
    for (0..SCREEN_WIDTH * SCREEN_HEIGHT) |i| {
        buffer[i] = 0x0;
    }

    const res = try utils.fetch_data("teapot.obj", allocator, .{ .vn = true, .vt = true, .f = true });
    const vertices = res.vertices;

    defer vertices.deinit();
    res.faces.deinit();
    res.face_textures.deinit();
    res.textures.deinit();

    for (vertices.items) |vertex| {
        const camera = vertex.point_mat_multiplication(world_to_camera);
        const projected = camera.point_mat_multiplication(projection_matrix);

        if (projected.x < -1 or projected.x > 1 or projected.y < -1 or projected.y > 1) continue;

        const x = @min(
            SCREEN_WIDTH - 1,
            @as(
                u32,
                @intFromFloat((projected.x + 1) * 0.5 * SCREEN_WIDTH),
            ),
        );
        const y = @min(
            SCREEN_HEIGHT - 1,
            @as(
                u32,
                @intFromFloat((1 - (projected.y + 1) * 0.5) * SCREEN_HEIGHT),
            ),
        );

        buffer[y * SCREEN_WIDTH + x] = 255;
    }

    var outputs = try std.fs.cwd().openDir("tests/outputs", .{});
    defer outputs.close();

    const ppm = try outputs.createFile("teapot.ppm", .{});
    defer ppm.close();

    _ = try ppm.write("P5\n");

    const line_2 = try std.fmt.allocPrint(
        allocator,
        "{d} {d}\n255\n",
        .{
            SCREEN_WIDTH,
            SCREEN_HEIGHT,
        },
    );
    defer allocator.free(line_2);

    _ = try ppm.write(line_2);
    _ = try ppm.write(&buffer);
}
