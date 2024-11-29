const std = @import("std");
const errors = @import("errors.zig").Errors;
const prims = @import("math/primitives.zig");

const sdl = @cImport({
    @cInclude("SDL2/SDL.h");
});

const ziglog = @import("ziglog");

pub const Engine = struct {
    window: ?*sdl.SDL_Window,
    renderer: ?*sdl.SDL_Renderer,
    running: bool = false,

    cam_position: prims.Vec3 = prims.Vec3{ .x = 0, .y = 0, .z = 0 },
    background_color: prims.Color4 = prims.RED,

    const Self = @This();

    fn format_error(comptime text: []const u8, err: [*c]const u8) ![]const u8 {
        return std.fmt.allocPrint(std.heap.page_allocator, text, .{err});
    }

    pub fn init(title: [*c]const u8) !Engine {
        const logger = try ziglog.Logger.get(.{});

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
        const window = sdl.SDL_CreateWindow(title, sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 800, 600, sdl.SDL_WINDOW_SHOWN);
        if (window == null) {
            try logger.err(try Engine.format_error("Window creation failed: {*}", sdl.SDL_GetError()));
            return errors.WindowCreationFailed;
        }
        try logger.info("Window creation successful.");

        // Create renderer
        const renderer = sdl.SDL_CreateRenderer(window, -1, sdl.SDL_RENDERER_ACCELERATED);
        if (renderer == null) {
            try logger.err(try Engine.format_error("Renderer creation failed: {*}", sdl.SDL_GetError()));
            return errors.RendererCreationFailed;
        }
        try logger.info("Renderer initialization successful.");

        return Engine{ .window = window, .renderer = renderer };
    }

    pub fn mainloop(self: *Self) !void {
        const logger = try ziglog.Logger.get(.{});

        self.running = true;

        var status = sdl.SDL_SetRenderDrawColor(self.renderer, self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a);
        if (status != 0) {
            try logger.err(try Engine.format_error("Setting render color failed: {*}", sdl.SDL_GetError()));
            return errors.SetRenderColorFailed;
        }

        var event: sdl.SDL_Event = undefined;
        while (self.running) {
            status = sdl.SDL_SetRenderDrawColor(self.renderer, self.background_color.r, self.background_color.g, self.background_color.b, self.background_color.a);
            if (status != 0) {
                try logger.err(try Engine.format_error("Setting render color failed: {*}", sdl.SDL_GetError()));
                return errors.SetRenderColorFailed;
            }

            status = sdl.SDL_RenderClear(self.renderer);
            if (status != 0) {
                try logger.err(try Engine.format_error("Clearing renderer failed: {*}", sdl.SDL_GetError()));
                return errors.RenderClearFailed;
            }

            while (sdl.SDL_PollEvent(&event) != 0) {
                if (event.type == sdl.SDL_QUIT) {
                    self.running = false;
                }
            }

            sdl.SDL_RenderPresent(self.renderer);
            sdl.SDL_Delay(16);
        }
    }

    pub fn deinit(self: *Self) void {
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_Quit();
    }
};
