const z3d = @import("z3d");
const std = @import("std");

const objectslib = z3d.graphics.objects;
const material = z3d.graphics.material;

const Object = z3d.graphics.objects.Object;
const Light = z3d.graphics.Light;
const RayCastingOptions = z3d.graphics.RayCastingOptions;
const Ray = z3d.graphics.Ray;

const Vec3 = z3d.math.Vec3f32;
const Vec2 = z3d.math.Vec2f32;

const ArrayList = std.ArrayList;
const allocator: std.mem.Allocator = std.testing.allocator;

fn render(
    options: *const RayCastingOptions,
    objects: *ArrayList(Object),
    lights: *ArrayList(Light),
) !void {
    var frame_buffer = try allocator.alloc(Vec3, @sizeOf(Vec3) * options.width * options.height);
    defer allocator.free(frame_buffer);

    const scale = @tan(z3d.math.DEG_TO_RAD * options.fov * 0.5);
    const screen_aspect_ratio = @as(f32, @floatFromInt(options.width)) / @as(f32, @floatFromInt(options.height));
    const origin = z3d.math.Vec3f32.diagonal(-1);

    for (0..options.height) |j| {
        for (0..options.width) |i| {
            const x = (2 * (@as(f32, @floatFromInt(i)) + 0.5) / @as(f32, @floatFromInt(options.width)) - 1) * screen_aspect_ratio * scale;
            const y = (1 - 2 * (@as(f32, @floatFromInt(j)) + 0.5) / @as(f32, @floatFromInt(options.height))) * scale;

            const direction = z3d.math.Vec3f32.init(x, y, -1).normalize();
            const ray = Ray{ .origin = origin, .direction = direction };
            frame_buffer[j * options.width + i] = z3d.graphics.cast_ray(
                ray,
                objects,
                lights,
                options,
                0,
            );
        }
    }

    var outputs = try std.fs.cwd().openDir("tests/outputs", .{});
    defer outputs.close();

    const ppm = try outputs.createFile("whitted.ppm", .{});
    defer ppm.close();

    _ = try ppm.write("P6\n");

    const line_2 = try std.fmt.allocPrint(
        allocator,
        "{d} {d}\n255\n",
        .{
            options.width,
            options.height,
        },
    );
    defer allocator.free(line_2);

    _ = try ppm.write(line_2);
    for (frame_buffer) |pixel| {
        const arr = [3]u8{
            @as(u8, @intFromFloat(@max(0.0, @min(1.0, pixel.x)) * 255)),
            @as(u8, @intFromFloat(@max(0.0, @min(1.0, pixel.y)) * 255)),
            @as(u8, @intFromFloat(@max(0.0, @min(1.0, pixel.z)) * 255)),
        };
        _ = try ppm.write(&arr);
    }
}

test "whitted ray casting" {
    var objects = ArrayList(Object).init(allocator);
    defer objects.deinit();

    var lights = ArrayList(Light).init(allocator);
    defer lights.deinit();

    var sph1_mat = material.Material{
        .material_type = material.MaterialType.DIFFUSE_AND_GLOSSY,
        .diffuse_color = Vec3.init(0.6, 0.7, 0.8),
    };

    var sph1_pos = Vec3.init(-1, 0, -12);
    const sph1 = Object{
        .sphere = objectslib.Sphere.init(
            &sph1_pos,
            2,
            &sph1_mat,
        ),
    };

    var sph2_mat = material.Material{
        .ior = 1.5,
        .material_type = material.MaterialType.REFLECTION_AND_REFRACTION,
    };

    var sph2_pos = Vec3.init(0.5, -1.5, -8);
    const sph2 = Object{
        .sphere = objectslib.Sphere.init(
            &sph2_pos,
            1.5,
            &sph2_mat,
        ),
    };

    try objects.append(sph1);
    try objects.append(sph2);

    var vertices_data = [_]Vec3{
        Vec3.init(-5, -3, -6),
        Vec3.init(5, -3, -6),
        Vec3.init(5, -3, -16),
        Vec3.init(-5, -3, -16),
    };
    var vertices: [*]Vec3 = &vertices_data;

    const vertex_indices = [6]usize{ 0, 1, 3, 1, 2, 3 };
    const textures = [4]Vec2{
        Vec2.init(0, 0),
        Vec2.init(1, 0),
        Vec2.init(1, 1),
        Vec2.init(0, 1),
    };

    var mesh_mat = material.Material{
        .material_type = material.MaterialType.DIFFUSE_AND_GLOSSY,
    };

    const mesh = Object{
        .mesh_triangle = objectslib.MeshTriangle.init(
            &vertices,
            4,
            &vertex_indices,
            2,
            &textures,
            &mesh_mat,
            null,
        ),
    };

    try objects.append(mesh);

    try lights.append(Light{
        .position = Vec3.init(-20, 70, 20),
        .intensity = Vec3.init(0.5, 0.5, 0.5),
    });

    try lights.append(Light{
        .position = Vec3.init(30, 50, -12),
        .intensity = Vec3.init(1, 1, 1),
    });

    const options = RayCastingOptions{
        .width = 640,
        .height = 480,
        .fov = 90,
        .background_color = Vec3{ .x = 0.235, .y = 0.674, .z = 0.84 },
        .max_depth = 5,
        .bias = 0.00001,
    };

    try render(&options, &objects, &lights);
}
