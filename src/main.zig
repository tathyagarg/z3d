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

    const positions = [_]*Vec3{
        @constCast(&Vec3.init(-3, 0, 0)),
        //@constCast(&Vec3.init(0, -3, 0)),
        @constCast(&Vec3.init(0, 0, -3)),
        @constCast(&Vec3.init(3, 0, 0)),
        @constCast(&Vec3.init(0, 0, 3)),
        //@constCast(&Vec3.init(0, 3, 0)),
    };

    const colors = [_]*graphics.material.Material{
        @constCast(&graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 255, .g = 0, .b = 0 } } }),
        @constCast(&graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 0, .g = 0, .b = 255 } } }),
        @constCast(&graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 255, .g = 255, .b = 0 } } }),
        @constCast(&graphics.material.Material{ .texture = Texture{ .SOLID_COLOR = RGB{ .r = 0, .g = 255, .b = 255 } } }),
    };

    for (positions, colors) |p, c| {
        const sphere = objects.Object{
            .sphere = objects.Sphere.init(p, 1, c),
        };
        try scene_objects.append(sphere);
    }

    // const vertices_data: []*Vec3 = @constCast(&[_]*Vec3{
    //     @constCast(&Vec3.init(9, 15, 15)),
    //     @constCast(&Vec3.init(15, 15, 15)),
    //     @constCast(&Vec3.init(15, 15, 9)),
    //     @constCast(&Vec3.init(9, 15, 9)),
    //     @constCast(&Vec3.init(9, 9, 15)),
    //     @constCast(&Vec3.init(15, 9, 15)),
    //     @constCast(&Vec3.init(15, 9, 9)),
    //     @constCast(&Vec3.init(9, 9, 9)),
    // });

    var image = try Image.init("tests/assets/textures/texture01.png");
    defer image.deinit();
    const mesh_mat = graphics.material.Material{
        .material_type = graphics.material.MaterialType.DIFFUSE_AND_GLOSSY,
        .texture = Texture{
            .TEXTURE_FILE = image,
        },
    };

    // try scene_objects.append(
    //     objects.Object{
    //         .mesh_triangle = objects.Cuboid(
    //             &vertices_data,
    //             &mesh_mat,
    //             null,
    //         ),
    //     },
    // );

    try scene_objects.append(
        objects.Object{
            .rectangle = objects.Rectangle.init(
                [_]Vec3{
                    Vec3.init(9, 15, 15),
                    Vec3.init(15, 15, 15),
                    Vec3.init(15, 15, 9),
                    Vec3.init(9, 15, 9),
                },
                &mesh_mat,
                null,
                true,
                //   false,
            ),
        },
    );

    const light = Light{
        .position = Vec3.init(0, 0, 0),
        .intensity = Vec3.diagonal(0.9),
    };

    const light2 = Light{
        .position = Vec3.init(12, 18, 12),
        .intensity = Vec3.diagonal(0.9),
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
