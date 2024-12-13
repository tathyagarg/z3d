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

const Vec3 = math.Vec3(f32);
const allocator = std.testing.allocator;

test "window initialization" {
    var sphere_mat = graphics.material.Material{
        .diffuse_color = Vec3.init(0.1, 0.2, 0.9),
    };

    var sphere_pos = Vec3.init(0, 0, -3);
    const sphere = objects.Object{
        .sphere = objects.Sphere.init(
            &sphere_pos,
            1,
            &sphere_mat,
        ),
    };
    // var phy = physics.PhysicsEngine.init(
    //     &sphere.sphere.position,
    //     .{ .acceleration = physics.GRAVITY, .mass = 1 },
    // );
    // sphere.add_physics(&phy);

    var sphere_mat2 = graphics.material.Material{
        .diffuse_color = Vec3.init(0.1, 0.9, 0.2),
    };

    var sphere_pos2 = Vec3.init(3, 0, 0);
    const sphere2 = objects.Object{
        .sphere = objects.Sphere.init(
            &sphere_pos2,
            1,
            &sphere_mat2,
        ),
    };

    var sphere_mat3 = graphics.material.Material{
        .diffuse_color = Vec3.init(0.9, 0.1, 0.2),
    };

    var sphere_pos3 = Vec3.init(-3, 0, 0);
    const sphere3 = objects.Object{
        .sphere = objects.Sphere.init(
            &sphere_pos3,
            1,
            &sphere_mat3,
        ),
    };
    // var phy2 = physics.PhysicsEngine.init(
    //     &sphere2.sphere.position,
    //     .{ .acceleration = physics.GRAVITY, .mass = 1 },
    // );
    // sphere2.add_physics(&phy2);

    var scene_objects = std.ArrayList(objects.Object).init(allocator);
    defer scene_objects.deinit();

    try scene_objects.append(sphere);
    try scene_objects.append(sphere2);
    try scene_objects.append(sphere3);

    const light = Light{
        .position = Vec3.init(0, 70, 0),
        .intensity = Vec3.init(0.8, 0.8, 0.8),
    };

    var lights = std.ArrayList(Light).init(allocator);
    defer lights.deinit();

    try lights.append(light);

    const cam = Camera{
        .position = Vec3.init(0, 0, 0),
        .direction = Vec3.init(0, 0, -1),
    };

    const scene = Scene.init(cam, &scene_objects, &lights, .{});
    var eng = try engine.Engine.init(
        "Z3D",
        1,
        1,
        400,
        400,
        engine.WindowFlags.default(),
        scene,
    );
    defer eng.deinit();

    try eng.mainloop();
}
