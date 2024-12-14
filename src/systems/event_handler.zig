const std = @import("std");
const sdl = @cImport(@cInclude("SDL2/SDL.h"));

const math = @import("../core/math/math.zig");

const float = @import("../core/constants.zig").FLOAT;
const Vec3 = @import("../core/math/math.zig").Vec3;
const Vec3f = Vec3(float);

const Event = sdl.SDL_Event;
const PositionHandler = @import("transform.zig").PositionHandler;

pub const EventHandler = packed struct {
    noop: bool = false,
    keyboard_movement: bool = false,
    mouse_movement: bool = false,

    const Self = @This();

    pub fn handle_event(self: Self, event: sdl.SDL_Event, position: *const PositionHandler) void {
        _ = .{ self, position };
        switch (event.type) {
            sdl.SDL_KEYDOWN => if (self.keyboard_movement) {
                const direction = position.get_direction();
                switch (event.key.keysym.sym) {
                    sdl.SDLK_UP, sdl.SDLK_w => {
                        position.translate(Vec3f.init(
                            @sin(direction.y * math.DEG_TO_RAD),
                            0,
                            @cos(direction.y * math.DEG_TO_RAD),
                        ));
                    },
                    sdl.SDLK_DOWN, sdl.SDLK_s => {
                        position.translate(Vec3f.init(
                            -@sin(direction.y * math.DEG_TO_RAD),
                            0,
                            -@cos(direction.y * math.DEG_TO_RAD),
                        ));
                    },
                    sdl.SDLK_LEFT, sdl.SDLK_a => {
                        position.translate(Vec3f.init(
                            -@cos(direction.y * math.DEG_TO_RAD),
                            0,
                            @sin(direction.y * math.DEG_TO_RAD),
                        ));
                    },
                    sdl.SDLK_RIGHT, sdl.SDLK_d => {
                        position.translate(Vec3f.init(
                            @cos(direction.y * math.DEG_TO_RAD),
                            0,
                            -@sin(direction.y * math.DEG_TO_RAD),
                        ));
                    },
                    else => {},
                }
            },
            sdl.SDL_MOUSEMOTION => {
                var x: i32, var y: i32 = .{ undefined, undefined };
                _ = sdl.SDL_GetMouseState(&x, &y);
                std.debug.print("MOVE {d} {d}!\n", .{ x, y });
            },
            else => {},
        }
    }
};
