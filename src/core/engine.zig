const std = @import("std");
const errors = @import("errors.zig").Errors;
const prims = @import("math/primitives.zig");
const Scene = @import("../scene/scene.zig").Scene;
const constants = @import("constants.zig");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const ziglog = @import("ziglog");

pub const Engine = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    running: bool = false,

    scene: Scene,
    background_color: prims.Color4 = prims.BLACK,

    const Self = @This();

    fn format_error(comptime text: []const u8, err: [*c]const u8) ![]const u8 {
        return std.fmt.allocPrint(std.heap.page_allocator, text, .{err});
    }

    pub fn init(title: [*c]const u8) !Engine {
        const logger = try ziglog.Logger.get(.{ .name = "main" });

        // Initialize SDL_INIT_VIDEO if not already initialized
        if (sdl.SDL_WasInit(sdl.SDL_INIT_VIDEO) != 0) {
            const initialization = sdl.SDL_Init(sdl.SDL_INIT_VIDEO);
            if (initialization != 0) {
                try logger.err(try Engine.format_error("Video initialization failed: {*}", sdl.SDL_GetError()));
                return errors.InitializationFailed;
            }
            try logger.info("Video initialization successful.");
        }

        // Create window
        const window = sdl.SDL_CreateWindow(
            title,
            sdl.SDL_WINDOWPOS_CENTERED,
            sdl.SDL_WINDOWPOS_CENTERED,
            constants.CANVAS_SIZE_X,
            constants.CANVAS_SIZE_Y,
            sdl.SDL_WINDOW_SHOWN,
        ) orelse {
            try logger.err(try Engine.format_error("Window creation failed: {*}", sdl.SDL_GetError()));
            return errors.WindowCreationFailed;
        };
        try logger.info("Window creation successful.");

        // Create renderer
        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED) orelse {
            try logger.err(try Engine.format_error("Renderer creation failed: {*}", sdl.SDL_GetError()));
            return errors.RendererCreationFailed;
        };
        try logger.info("Renderer initialization successful.");

        return Engine{ .window = window, .renderer = renderer, .scene = try Scene.init(renderer) };
    }

    pub fn mainloop(self: *Self) !void {
        self.running = true;

        var event: sdl.SDL_Event = undefined;
        while (self.running) {
            try self.scene.render();

            while (sdl.SDL_PollEvent(&event) != 0) {
                if (event.type == sdl.SDL_QUIT) {
                    self.running = false;
                }
            }

            sdl.SDL_RenderPresent(self.renderer);
            sdl.SDL_Delay(constants.FRAME_DELAY);
        }
    }

    pub fn deinit(self: *Self) void {
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_Quit();
    }
};
