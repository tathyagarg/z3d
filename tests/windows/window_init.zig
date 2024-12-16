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

const Vec3 = math.Vec3(f32);
const allocator = std.testing.allocator;

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
    const cam = Camera{ .position = &pos_handler };

    const scene = Scene.init(cam, &scene_objects, &lights, .{ .ray_casting_options = &.{ .height = 600, .width = 600 } });
    var eng = try engine.Engine.init(
        "Z3D",
        1,
        1,
        600,
        600,
        engine.WindowFlags.default(),
        scene,
    );
    defer eng.deinit();

    try eng.mainloop();
}
