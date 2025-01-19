const z3d = @import("root.zig");
const std = @import("std");

const engine = z3d.engine;
const graphics = z3d.graphics;
const math = z3d.math;
const physics = z3d.physics;
const Scene = z3d.engine.Scene;
const objects = graphics.objects;
const Light = graphics.Light;
const Camera = engine.Camera;
const transform = z3d.transform;
const EventHandler = z3d.event_handler.EventHandler;
const RGB = graphics.RGB;
const Texture = graphics.material.Texture;
const Image = z3d.images.Image;

const Vec3 = math.Vec3(f32);
const Vec2 = math.Vec2(f32);
const allocator = std.heap.page_allocator;

const HEIGHT = 400;
const WIDTH = 400;

pub fn main() !void {
    var scene_objects = std.ArrayList(objects.Object).init(allocator);
    defer scene_objects.deinit();

    const positions = [_]Vec3{
        Vec3.init(-3, 0, 0),
        Vec3.init(0, 0, -3),
        Vec3.init(3, 0, 0),
        Vec3.init(0, 0, 3),
    };

    const colors = [_]graphics.material.Material{
        graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 255, .g = 0, .b = 0 } } },
        graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 0, .g = 0, .b = 255 } } },
        graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 255, .g = 255, .b = 0 } } },
        graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 0, .g = 255, .b = 255 } } },
    };

    for (0..positions.len) |i| {
        const sphere = objects.Object{
            .sphere = objects.Sphere.init(@constCast(&positions[i]), 1, &colors[i]),
        };
        try scene_objects.append(sphere);
    }

    const vertices_data: [8]Vec3 = [8]Vec3{
        Vec3.init(9, 15, 15),
        Vec3.init(15, 15, 15),
        Vec3.init(15, 15, 9),
        Vec3.init(9, 15, 9),
        Vec3.init(9, 9, 15),
        Vec3.init(15, 9, 15),
        Vec3.init(15, 9, 9),
        Vec3.init(9, 9, 9),
    };

    var image = try Image.init("tests/assets/textures/texture01.png");
    defer image.deinit();
    const mesh_mat = graphics.material.Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image,
        },
    };

    for (objects.Cuboid(vertices_data, &mesh_mat, null, true)) |rectangle| {
        try scene_objects.append(
            objects.Object{
                .rectangle = @constCast(&rectangle).rotate_counterclockwise(1).*,
            },
        );
    }

    const light = Light{
        .position = Vec3.init(0, 0, 0),
        .intensity = Vec3.diagonal(0.9),
    };

    const light2 = Light{
        .position = Vec3.init(18, 18, 18),
        .intensity = Vec3.diagonal(1),
    };

    var lights = std.ArrayList(Light).init(allocator);
    defer lights.deinit();

    try lights.append(light);
    try lights.append(light2);

    // const cam = Camera{
    //     .position = &transform.PositionHandler{
    //         .single = transform.SinglePointHandler{
    //             .point = @constCast(&Vec3.init(0, 0, 0)),
    //         },
    //     },
    //     .direction = @constCast(&Vec3.init(0, 90, 0)),
    // };
    const pos_handler = transform.PositionHandler{ .single = transform.SinglePointHandler{
        .point = @constCast(&Vec3.zero()),
        .direction = @constCast(&Vec3.zero()),
    } };
    const cam = Camera{
        .position = &pos_handler,
        .event_handler = &EventHandler{
            .keyboard_movement = true,
            .mouse_movement = true,
            .width = WIDTH,
            .height = HEIGHT,
        },
    };

    const scene = try Scene.init(
        cam,
        &scene_objects,
        &lights,
        .{
            .ray_casting_options = &graphics.RayCastingOptions{
                .width = WIDTH,
                .height = HEIGHT,
                .fov = 90,
            },
            .cpu_count = 4,
        },
    );
    var eng = try engine.Engine.init(
        "Z3D",
        1,
        1,
        WIDTH,
        HEIGHT,
        engine.WindowFlags.default(),
        scene,
    );
    defer eng.deinit();

    try eng.mainloop();
}
