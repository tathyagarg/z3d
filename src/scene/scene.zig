const Camera = @import("camera.zig").Camera;
const prims = @import("../core/math/primitives.zig");
const constants = @import("../core/constants.zig");
const std = @import("std");

const ziglog = @import("ziglog");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Scene = struct {
    camera: Camera = undefined,
    background_color: prims.Color4 = prims.WHITE,

    renderer: *sdl.SDL_Renderer,

    // Change from i32 to object later
    objects: []i32 = &[_]i32{},

    pub fn init(renderer: *sdl.SDL_Renderer) !Scene {
        var scene = Scene{ .renderer = renderer };
        const camera = try Camera.init(scene);
        scene.camera = camera;

        return scene;
    }

    pub fn render(self: Scene) !void {
        const logger = try ziglog.Logger.get(.{ .name = "console" });

        for (0.., self.camera.canvas) |i, pixel| {
            if (pixel.r != 255 or pixel.g != 255 or pixel.b != 255) {
                try logger.debug(try std.fmt.allocPrint(
                    std.heap.page_allocator,
                    "r: {d} g: {d} b: {d} a: {d} i: {d}",
                    .{ pixel.r, pixel.g, pixel.b, pixel.a, i },
                ));
            }
            _ = sdl.SDL_SetRenderDrawColor(self.renderer, pixel.r, pixel.g, pixel.b, pixel.a);
            _ = sdl.SDL_RenderDrawPoint(self.renderer, @intCast(i / constants.CANVAS_SIZE_Y), @intCast(i % constants.CANVAS_SIZE_Y));
        }
    }
};
