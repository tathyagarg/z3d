const z3d = @import("z3d");
const std = @import("std");

const engine = z3d.engine;
const graphics = z3d.graphics;
const math = z3d.math;
const physics = z3d.physics;
const Scene = z3d.engine.Scene;
const objects = graphics.objects;
const Light = graphics.Light;

const Vec3 = math.Vec3(f32);
const allocator = std.testing.allocator;

test "window initialization" {
    var sphere_mat = graphics.material.Material{
        .diffuse_color = Vec3.init(0.1, 0.2, 0.9),
    };

    var sphere_pos = Vec3.init(0, 0, -10);
    var sphere = objects.Object{
        .sphere = objects.Sphere.init(
            &sphere_pos,
            3,
            &sphere_mat,
        ),
    };
    var phy = physics.PhysicsEngine.init(
        &sphere.sphere.position,
        .{ .force = Vec3.init(0, 1, 0) },
    );
    sphere.add_physics(&phy);

    var scene_objects = std.ArrayList(objects.Object).init(allocator);
    defer scene_objects.deinit();

    try scene_objects.append(sphere);

    const light = Light{
        .position = Vec3.init(-20, 70, 20),
        .intensity = Vec3.init(0.8, 0.8, 0.8),
    };

    var lights = std.ArrayList(Light).init(allocator);
    defer lights.deinit();

    try lights.append(light);

    const scene = Scene.init(&scene_objects, &lights, .{});
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
