const std = @import("std");

const Engine = @import("core/engine.zig").Engine;
const Shape = @import("graphics/shape.zig").Shape;
const Triangle = @import("graphics/shapes/triangle.zig").Triangle;
const Vec3 = @import("core/math/primitives.zig").Vec3;
const Color4 = @import("core/math/primitives.zig").Color4;
const ziglog = @import("ziglog");

pub fn main() !void {
    const logger = try ziglog.Logger.get(.{ .sink = .file, .file_path = ".log", .name = "main" });
    _ = try ziglog.Logger.get(.{ .name = "console", .sink = .console });

    try logger.debug("Initializing application.");
    var engine = try Engine.init("Z3D");
    defer engine.deinit();

    try engine.add_shape(Shape{
        .triangle = Triangle{ .points = .{
            .a = Vec3{ .x = 30, .y = 20, .z = 0.9 },
            .b = Vec3{ .x = 40, .y = 35, .z = 0.9 },
            .c = Vec3{ .x = 9, .y = 11, .z = 0.9 },
        }, .color = Color4{
            .r = 0,
            .g = 0,
            .b = 0,
            .a = 100,
        } },
    });

    try engine.add_shape(Shape{
        .triangle = Triangle{ .points = .{
            .a = Vec3{ .x = 30, .y = 50, .z = 0.3 },
            .b = Vec3{ .x = 29, .y = 35, .z = 0.5 },
            .c = Vec3{ .x = 6, .y = 11, .z = 0.5 },
        }, .color = Color4{
            .r = 255,
            .g = 255,
            .b = 255,
            .a = 100,
        } },
    });

    try logger.debug(try std.fmt.allocPrint(
        std.heap.page_allocator,
        "Shapes count: {d}",
        .{engine.scene.shapes.items.len},
    ));

    try engine.mainloop();
    try logger.debug("Initialization complete");
}
