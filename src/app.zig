const std = @import("std");
const debug = std.debug.print;
const errors = @import("errors.zig").Errors;
const models = @import("models.zig");
const Atom = @import("render/atom.zig").Atom;

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

pub const Application = struct {
    window: ?*sdl.SDL_Window,
    renderer: ?*sdl.SDL_Renderer,
    running: bool = false,

    cam_position: models.Position = models.Position.init(0, 0, 0),
    background_color: models.Color = models.Color.BLACK,

    const Self = @This();
    pub fn init(title: [*c]const u8) !Application {
        // Initialize SDL_INIT_VIDEO if not already initialized
        if (sdl.SDL_WasInit(sdl.SDL_INIT_VIDEO) != 0) {
            const initialization = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
            if (initialization != 0) {
                debug("Video initialization failed: {*}", .{sdl.SDL_GetError()});
                return errors.InitializationFailed;
            }
        }

        // Create window
        const window = sdl.SDL_CreateWindow(title, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 800, 600, sdl.SDL_WINDOW_SHOWN);
        if (window == null) {
            debug("Window creation failed: {*}", .{sdl.SDL_GetError()});
            return errors.WindowCreationFailed;
        }

        // Create renderer
        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED);
        if (renderer == null) {
            debug("Renderer creation failed: {*}", .{sdl.SDL_GetError()});
            return errors.RendererCreationFailed;
        }

        return Application{ .window = window, .renderer = renderer };
    }

    pub fn mainloop(self: *Self) !void {
        defer self.destroy();
        self.running = true;

        var status = sdl.SDL_SetRenderDrawColor(self.renderer, self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a);
        if (status != 0) {
            debug("Setting render color failed: {*}", .{sdl.SDL_GetError()});
            return errors.SetRenderColorFailed;
        }

        const atoms = [_]Atom{ Atom.Hydrogen, Atom.Oxygen };
        //        debug("{}", .{atoms});

        var event: sdl.SDL_Event = undefined;
        while (self.running) {
            status = sdl.SDL_SetRenderDrawColor(self.renderer, self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a);
            if (status != 0) {
                debug("Setting render color failed: {*}", .{sdl.SDL_GetError()});
                return errors.SetRenderColorFailed;
            }

            status = sdl.SDL_RenderClear(self.renderer);
            if (status != 0) {
                debug("Clearing renderer failed: {*}", .{sdl.SDL_GetError()});
                return errors.RenderClearFailed;
            }

            while (sdl.SDL_PollEvent(&event) != 0) {
                if (event.type == sdl.SDL_QUIT) {
                    self.running = false;
                }
            }

            for (atoms) |atom| {
                try atom.render(self.renderer);
            }

            sdl.SDL_RenderPresent(self.renderer);
            sdl.SDL_Delay(16);
        }
    }

    pub fn destroy(self: *Self) void {
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_Quit();
    }
};
