const z3d = @import("root.zig");
const std = @import("std");

const engine = z3d.engine;
const graphics = z3d.graphics;
const math = z3d.math;
const physics = z3d.physics;
const gui = z3d.gui;
const Scene = z3d.engine.Scene;
const objects = graphics.objects;
const Light = graphics.Light;
const Camera = engine.Camera;
const transform = z3d.transform;
const EventHandler = z3d.event_handler.EventHandler;
const RGB = graphics.RGB;
const Texture = graphics.material.Texture;
const Image = z3d.images.Image;
const Material = graphics.material.Material;

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

    const colors = [_]Material{
        Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 255, .g = 0, .b = 0 } } },
        Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 0, .g = 0, .b = 255 } } },
        Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 255, .g = 255, .b = 0 } } },
        Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 0, .g = 255, .b = 255 } } },
    };

    for (0..positions.len) |i| {
        var sphere = objects.Object{
            .sphere = objects.Sphere.init(@constCast(&positions[i]), 1, &colors[i]),
        };
        objects.assigned(&sphere);
        try scene_objects.append(sphere);
    }

    var physics_eng = physics.PhysicsEngine.init(
        scene_objects.items[3],
        .{},
    );
    physics_eng.apply_gravity(null);

    scene_objects.items[0].add_physics(&physics_eng);

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

    var image2 = try Image.init("tests/assets/textures/texture02.png");
    defer image2.deinit();

    var image3 = try Image.init("tests/assets/textures/texture03.png");
    defer image3.deinit();

    var image4 = try Image.init("tests/assets/textures/texture04.png");
    defer image4.deinit();

    var image5 = try Image.init("tests/assets/textures/texture05.png");
    defer image5.deinit();

    var image6 = try Image.init("tests/assets/textures/texture06.png");
    defer image6.deinit();

    const left_mesh_mat = Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image,
        },
    };

    const right_mesh_mat = Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image2,
        },
    };

    const front_mesh_mat = Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image3,
        },
    };

    const back_mesh_mat = Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image4,
        },
    };

    const top_mesh_mat = Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image5,
        },
    };

    const bottom_mesh_mat = Material{
        .material_type = .DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image6,
        },
    };

    const materials = graphics.objects.CuboidMaterial{
        .PerFace = graphics.objects.PerFace{
            .top = &top_mesh_mat,
            .bottom = &bottom_mesh_mat,
            .left = &left_mesh_mat,
            .right = &right_mesh_mat,
            .front = &front_mesh_mat,
            .back = &back_mesh_mat,
        },
    };
    _ = .{ materials, vertices_data };

    for (objects.Cuboid(&vertices_data, materials, true)) |rectangle| {
        var rect_obj = objects.Object{ .rectangle = rectangle };
        objects.assigned(&rect_obj);
        try scene_objects.append(rect_obj);
    }

    var rect = objects.Object{
        .rectangle = objects.Rectangle.init(
            Vec3.init(-6, -6, -6),
            Vec3.init(-6, -6, 6),
            Vec3.init(6, -6, 6),
            Vec3.init(6, -6, -6),
            &left_mesh_mat,
            false,
        ),
    };
    objects.assigned(&rect);
    try scene_objects.append(rect);

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

    var gui_layer = gui.GUI_Layer.init(allocator);
    defer gui_layer.deinit();

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
        &gui_layer,
    );
    try scene.gui.add_gui(gui.GUI_Element{
        .Image = gui.GUI_Image{
            .image = image6,
            .position = gui.GUI_Bounds{
                .top_left = Vec2.init(0, 0),
                .bottom_right = Vec2.init(100, 100),
            },
        },
    });

    var eng = try engine.Engine.init(
        "Z3D",
        1,
        1,
        WIDTH,
        HEIGHT,
        engine.WindowFlags.default(),
        scene,
        allocator,
    );
    defer eng.deinit();

    try eng.mainloop();
}
