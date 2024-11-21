const models = @import("../models.zig");
const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});
const errors = @import("../errors.zig").Errors;
const std = @import("std");

pub const Atom = struct {
    color: models.Color,
    position: models.Position,
    mass: u64,
    radius: u64,

    const Self = @This();

    pub fn init(color: models.Color, position: models.Position, mass: u64, radius: u64) Atom {
        return Atom{ .color = color, .position = position, .mass = mass, .radius = radius };
    }

    /// The render method of an atom has the task to draw a circle to the renderer
    /// This function utilizes Jesko's method to draw rasterized circles.
    /// Reference: https://web.archive.org/web/20240811175016/https://schwarzers.com/algorithms/
    pub fn render(self: Self, renderer: ?*sdl.SDL_Renderer) !void {
        if (renderer == null) {
            return errors.RendererNotGiven;
        }

        const status = sdl.SDL_SetRenderDrawColor(renderer, self.color.r, self.color.g, self.color.b, self.color.a);
        if (status != 0) {
            return errors.SetRenderColorFailed;
        }

        var x: i64 = @intCast(self.radius);
        var y: i64 = 0;
        var t1: i64 = @intCast(self.radius >> 4);
        var t2: i64 = t1 - x;

        while (x >= y) {
            // Draw original 4 points
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(x + 100), @intCast(y + 100));
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(-x + 100), @intCast(y + 100));
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(x + 100), @intCast(-y + 100));
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(-x + 100), @intCast(-y + 100));

            // The following lines create copies of the 4 original points, mirrored across the diagonals.
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(-y + 100), @intCast(-x + 100));
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(y + 100), @intCast(x + 100));
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(y + 100), @intCast(-x + 100));
            _ = sdl.SDL_RenderDrawPoint(renderer, @intCast(-y + 100), @intCast(x + 100));

            y += 1;
            t1 += y;
            t2 = t1 - x;
            if (t2 >= 0) {
                t1 = t2;
                x -= 1;
            }
        }
    }

    pub const Hydrogen = Atom.init(models.Color.RED, models.Position.init(10, 10, 10), 1, 20);
    pub const Oxygen = Atom.init(models.Color.WHITE, models.Position.init(10, 10, 10), 16, 70);
};
