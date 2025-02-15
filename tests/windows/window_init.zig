const z3d = @import("z3d");
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

const Vec3 = math.Vec3(f32);
const Vec2 = math.Vec2(f32);
const allocator = std.testing.allocator;

const HEIGHT = 500;
const WIDTH = 500;

test "window initialization" {
    var scene_objects = std.ArrayList(objects.Object).init(allocator);
    defer scene_objects.deinit();

    const positions = [_]*Vec3{
        @constCast(&Vec3.init(-3, 0, 0)),
        //@constCast(&Vec3.init(0, -3, 0)),
        @constCast(&Vec3.init(0, 0, -3)),
        @constCast(&Vec3.init(3, 0, 0)),
        @constCast(&Vec3.init(0, 0, 3)),
        //@constCast(&Vec3.init(0, 3, 0)),
    };

    const colors = [_]*graphics.material.Material{
        @constCast(&graphics.material.Material{ .diffuse_color = Vec3.init(1, 0, 0) }),
        //@constCast(&graphics.material.Material{ .diffuse_color = Vec3.init(0, 1, 0) }),
        @constCast(&graphics.material.Material{ .diffuse_color = Vec3.init(0, 0, 1) }),
        @constCast(&graphics.material.Material{ .diffuse_color = Vec3.init(1, 1, 0) }),
        @constCast(&graphics.material.Material{ .diffuse_color = Vec3.init(0, 1, 1) }),
        //@constCast(&graphics.material.Material{ .diffuse_color = Vec3.init(1, 0, 1) }),
    };

    for (positions, colors) |p, c| {
        const sphere = objects.Object{
            .sphere = objects.Sphere.init(p, 1, c),
        };
        try scene_objects.append(sphere);
    }

    var vertices_data = [_]Vec3{
        Vec3.init(-5, -3, -6),
        Vec3.init(5, -3, -6),
        Vec3.init(5, -3, -16),
        Vec3.init(-5, -3, -16),
    };
    const vertices: *[*]Vec3 = @ptrCast(&vertices_data);

    const vertex_indices = [6]usize{ 0, 1, 3, 1, 2, 3 };
    const textures = [4]Vec2{
        Vec2.init(0, 0),
        Vec2.init(1, 0),
        Vec2.init(1, 1),
        Vec2.init(0, 1),
    };

    const mesh_mat = graphics.material.Material{
        .material_type = graphics.material.MaterialType.DIFFUSE_AND_GLOSSY,
    };

    try scene_objects.append(objects.Object{ .mesh_triangle = objects.MeshTriangle.init(
        vertices,
        vertices_data.len,
        &vertex_indices,
        2,
        &textures,
        &mesh_mat,
        null,
    ) });

    const light = Light{
        .position = Vec3.init(0, 0, 0),
        .intensity = Vec3.diagonal(0.9),
    };

    var lights = std.ArrayList(Light).init(allocator);
    defer lights.deinit();

    try lights.append(light);

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

    const scene = Scene.init(
        cam,
        &scene_objects,
        &lights,
        .{
            .ray_casting_options = &graphics.RayCastingOptions{
                .width = WIDTH,
                .height = HEIGHT,
                .fov = 90,
            },
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
