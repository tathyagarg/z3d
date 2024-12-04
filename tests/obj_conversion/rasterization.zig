const z3d = @import("z3d");
const std = @import("std");
const utils = @import("utils.zig");

const _Mat4 = z3d.math.Mat4;
const Vec3Vertex = utils.Vec3Vertex;
const Vec2Texture = utils.Vec2Texture;

const line_string = utils.LINE_STRING;
const allocator = std.testing.allocator;
const Mat4 = _Mat4(utils.VERTEX_TYPE);
const RGB = z3d.graphics.types.RGB;

const focal_length = 20; // in mm
const film_aperture_width = 0.980; // in in.
const film_aperture_height = 0.735; // in in.

const near_clipping = 1;
const far_clipping = 1_000;

const film_fit = z3d.graphics.FitResolutionGate.kOverscan;

const SCREEN_HEIGHT = 480;
const SCREEN_WIDTH = 640;

test "rasterization" {
    const world_to_camera = Mat4.from([4][4]utils.VERTEX_TYPE{
        .{ 0.707107, -0.331295, 0.624695, 0 },
        .{ 0, 0.883452, 0.468521, 0 },
        .{ -0.707107, -0.331295, 0.624695, 0 },
        .{ -1.63871, -5.747777, -40.400412, 1 },
    });

    const screen_coordinates = z3d.graphics.compute_screen_coordinates(
        film_aperture_width,
        film_aperture_height,
        SCREEN_WIDTH,
        SCREEN_HEIGHT,
        film_fit,
        near_clipping,
        focal_length,
    );

    const top = screen_coordinates.top;
    const right = screen_coordinates.right;
    const bottom = screen_coordinates.bottom;
    const left = screen_coordinates.left;

    const computation_consts = z3d.math.PixelComputationOptions{
        .bottom = bottom,
        .left = left,
        .top = top,
        .right = right,
        .near = near_clipping,
        .screen_width = SCREEN_WIDTH,
        .screen_height = SCREEN_HEIGHT,
    };

    const res = try utils.fetch_data("cow.obj", std.testing.allocator);
    var vertices = res.vertices;
    var faces = res.faces;
    var textures = res.textures;
    var face_textures = res.face_textures;

    defer vertices.deinit();
    defer faces.deinit();
    defer textures.deinit();
    defer face_textures.deinit();

    var frame_buffer: [SCREEN_WIDTH * SCREEN_HEIGHT]RGB = undefined;
    var depth_buffer: [SCREEN_WIDTH * SCREEN_HEIGHT]f32 = undefined;

    for (0..SCREEN_WIDTH * SCREEN_HEIGHT) |i| {
        frame_buffer[i] = RGB.WHITE;
        depth_buffer[i] = far_clipping;
    }

    for (faces.items, face_textures.items) |face, face_texture| {
        const v0world = vertices.items[face.x];
        const v1world = vertices.items[face.y];
        const v2world = vertices.items[face.z];

        var v0raster = try v0world.convert_to_raster(world_to_camera, computation_consts);
        var v1raster = try v1world.convert_to_raster(world_to_camera, computation_consts);
        var v2raster = try v2world.convert_to_raster(world_to_camera, computation_consts);

        v0raster.z = 1 / v0raster.z;
        v1raster.z = 1 / v1raster.z;
        v2raster.z = 1 / v2raster.z;

        const pre_texture0 = textures.items[face_texture.x];
        const pre_texture1 = textures.items[face_texture.y];
        const pre_texture2 = textures.items[face_texture.z];

        const texture0 = pre_texture0.multiply(v0raster.z);
        const texture1 = pre_texture1.multiply(v1raster.z);
        const texture2 = pre_texture2.multiply(v2raster.z);

        const xmin = @min(v0raster.x, v1raster.x, v2raster.x);
        const ymin = @min(v0raster.y, v1raster.y, v2raster.y);
        const xmax = @max(v0raster.x, v1raster.x, v2raster.x);
        const ymax = @max(v0raster.y, v1raster.y, v2raster.y);

        if (xmin > SCREEN_WIDTH - 1 or xmax < 0 or ymin > SCREEN_HEIGHT - 1 or ymax < 0) continue;

        const x0: u32 = @max(0, @as(u32, @intFromFloat(@floor(xmin))));
        const y0: u32 = @max(0, @as(u32, @intFromFloat(@floor(ymin))));

        const x1: u32 = @min(SCREEN_WIDTH - 1, @as(u32, @intFromFloat(@floor(xmax))));
        const y1: u32 = @min(SCREEN_HEIGHT - 1, @as(u32, @intFromFloat(@floor(ymax))));

        const area = z3d.math.edge_function(utils.VERTEX_TYPE, v0raster, v1raster, v2raster);

        for (y0..y1 + 1) |y| {
            for (x0..x1 + 1) |x| {
                const pixel_sample = Vec3Vertex.init(
                    @as(utils.VERTEX_TYPE, @floatFromInt(x)) + 0.5,
                    @as(utils.VERTEX_TYPE, @floatFromInt(y)) + 0.5,
                    0,
                );

                var w0 = z3d.math.edge_function(utils.VERTEX_TYPE, v1raster, v2raster, pixel_sample);
                var w1 = z3d.math.edge_function(utils.VERTEX_TYPE, v2raster, v0raster, pixel_sample);
                var w2 = z3d.math.edge_function(utils.VERTEX_TYPE, v0raster, v1raster, pixel_sample);

                if (w0 >= 0 and w1 >= 0 and w2 >= 0) {
                    w0 /= area;
                    w1 /= area;
                    w2 /= area;

                    const one_over_z = v0raster.z * w0 +
                        v1raster.z * w1 +
                        v2raster.z * w2;
                    const z = 1 / one_over_z;

                    if (z < depth_buffer[y * SCREEN_WIDTH + x]) {
                        depth_buffer[y * SCREEN_WIDTH + x] = z;
                        var texture = texture0.multiply(w0)
                            .add(texture1.multiply(w1))
                            .add(texture2.multiply(w2));

                        texture = texture.multiply(z);

                        const v0camera = v0world.point_mat_multiplication(world_to_camera);
                        const v1camera = v1world.point_mat_multiplication(world_to_camera);
                        const v2camera = v2world.point_mat_multiplication(world_to_camera);

                        const px = (w0 * try v0camera.x_projection()) +
                            (w1 * try v1camera.x_projection()) +
                            (w2 * try v2camera.x_projection());

                        const py = (w0 * try v0camera.y_projection()) +
                            (w1 * try v1camera.y_projection()) +
                            (w2 * try v2camera.y_projection());

                        const pt = Vec3Vertex.init(px * z, py * z, -z);
                        const n = v1camera.subtract(v0camera)
                            .cross(v2camera.subtract(v0camera))
                            .normalize();

                        const view_direction = pt.negate().normalize();

                        var n_dot_view = @max(0, n.dot(view_direction));

                        const M = 10;
                        const checker = @as(utils.VERTEX_TYPE, @floatFromInt(@intFromBool(@mod(texture.x * M, 1) > 0.5) ^
                            @intFromBool(@mod(texture.y * M, 1) < 0.5)));

                        const c = 0.3 * (1 - checker) + 0.7 * checker;
                        n_dot_view *= c;

                        frame_buffer[y * SCREEN_WIDTH + x].r = @intFromFloat(n_dot_view * 255);
                        frame_buffer[y * SCREEN_WIDTH + x].g = @intFromFloat(n_dot_view * 255);
                        frame_buffer[y * SCREEN_WIDTH + x].b = @intFromFloat(n_dot_view * 255);
                    }
                }
            }
        }
    }

    var outputs = try std.fs.cwd().openDir("tests/outputs", .{});
    defer outputs.close();

    const svg = try outputs.createFile("cow.ppm", .{});
    defer svg.close();

    _ = try svg.write("P6\n");

    const line_2 = try std.fmt.allocPrint(
        allocator,
        "{d} {d}\n255\n",
        .{
            SCREEN_WIDTH,
            SCREEN_HEIGHT,
        },
    );
    defer allocator.free(line_2);

    _ = try svg.write(line_2);
    for (frame_buffer) |pixel| {
        const arr = [3]u8{ pixel.r, pixel.g, pixel.b };
        _ = try svg.write(&arr);
    }
}
