// ====== PUBLICLY SHARED ===============

pub const scenelib = @import("scene.zig");
pub const Scene = scenelib.Scene;

pub const cameralib = @import("camera.zig");
pub const Camera = cameralib.Camera;

// ======================================

const sdl = @cImport(@cInclude("SDL2/SDL.h"));
const std = @import("std");
const allocator = std.heap.page_allocator;

const math = @import("../core/math/math.zig");
const float = @import("../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);
const RGB = @import("../systems/graphics/graphics.zig").RGB;

pub const WindowFlags = packed struct {
    FULLSCREEN: bool = false,
    SHOWN: bool = false,
    HIDDEN: bool = false,
    BORDERLESS: bool = false,
    RESIZABLE: bool = false,
    MINIMIZED: bool = false,
    MAXIMIZED: bool = false,
    MOUSE_GRABBED: bool = false,
    INPUT_FOCUS: bool = false,
    MOUSE_FOCUS: bool = false,
    FOREIGN: bool = false,
    FULLSCREEN_DESKTOP: bool = false,
    ALLOW_HIGH_DPI: bool = false,

    pub fn default() WindowFlags {
        return WindowFlags{ .SHOWN = true };
    }

    pub fn as_int(self: WindowFlags) u32 {
        return @as(u32, @intCast(@as(u13, @bitCast(self))));
    }
};

pub const Engine = struct {
    window: *sdl.SDL_Window,
    renderer: *sdl.SDL_Renderer,
    width: u16,
    height: u16,
    frame_buffer: []RGB = undefined,
    scene: Scene,

    prev: usize = 0,

    pub fn init(
        title: [*:0]const u8,
        x: u16,
        y: u16,
        width: u16,
        height: u16,
        flags: WindowFlags,
        scene: Scene,
    ) !Engine {
        if (sdl.SDL_Init(sdl.SDL_INIT_EVERYTHING) != 0) {
            std.debug.print("{any}\n", .{sdl.SDL_GetError()});
            return error.EngineInitializationFailed;
        }

        const window = sdl.SDL_CreateWindow(
            title,
            x,
            y,
            width,
            height,
            flags.as_int(),
        ) orelse {
            std.debug.print("{any}\n", .{sdl.SDL_GetError()});
            return error.WindowInitializationFailed;
        };
        _ = sdl.SDL_SetWindowGrab(window, sdl.SDL_TRUE);
        _ = sdl.SDL_ShowCursor(sdl.SDL_DISABLE);
        _ = sdl.SDL_SetRelativeMouseMode(sdl.SDL_TRUE);

        const renderer = sdl.SDL_CreateRenderer(
            window,
            -1,
            0,
        ) orelse {
            std.debug.print("{any}\n", .{sdl.SDL_GetError()});
            return error.RendererInitializationFailed;
        };

        var initial_frame_buf = try allocator.alloc(
            RGB,
            @sizeOf(RGB) *
                @as(usize, @intCast(width)) *
                @as(usize, @intCast(height)),
        );

        try scene.render(&initial_frame_buf);

        return Engine{
            .window = window,
            .renderer = renderer,
            .width = width,
            .height = height,
            .frame_buffer = initial_frame_buf,
            .scene = scene,
        };
    }

    pub fn deinit(self: Engine) void {
        allocator.free(self.frame_buffer);
        sdl.SDL_DestroyRenderer(self.renderer);
        sdl.SDL_DestroyWindow(self.window);
        sdl.SDL_Quit();
    }

    pub fn mainloop(self: *Engine) !void {
        var event: sdl.SDL_Event = undefined;
        var running = true;

        while (running) {
            // self.scene.camera.direction.y += 5;
            // self.scene.camera.direction.x = @sin(2 * self.scene.camera.direction.y * math.DEG_TO_RAD) * 10;
            while (sdl.SDL_PollEvent(&event) != 0) {
                if (event.type == sdl.SDL_QUIT) {
                    running = false;
                } else {
                    self.scene.camera.handle_event(event);
                }
            }

            for (self.scene.objects.items) |o| {
                var phy = o.get_physics_engine() orelse continue;
                try phy.update();
            }
            try self.scene.render(&self.frame_buffer);

            const current = @as(usize, sdl.SDL_GetTicks());
            std.debug.print("FPS: {d}\n", .{1000 / (current - self.prev)});

            for (0..self.height) |j| {
                for (0..self.width) |i| {
                    const rgb = self.frame_buffer[j * self.height + i];
                    const r = rgb.r;
                    const g = rgb.g;
                    const b = rgb.b;
                    if (sdl.SDL_SetRenderDrawColor(self.renderer, r, g, b, 100) != 0) {
                        std.debug.print("\nSetErr: {any} ({d} {d} {d} {any})\n", .{ sdl.SDL_GetError(), r, g, b, rgb });
                        return error.SetRenderDrawColorFailed;
                    }

                    if (sdl.SDL_RenderDrawPoint(
                        self.renderer,
                        @as(c_int, @intCast(i)),
                        @as(c_int, @intCast(j)),
                    ) != 0) {
                        std.debug.print("\nDrawErr: {any}\n", .{sdl.SDL_GetError()});
                        return error.DrawPointFailed;
                    }
                }
            }

            sdl.SDL_RenderPresent(self.renderer);
            self.prev = current;
        }
    }
};
