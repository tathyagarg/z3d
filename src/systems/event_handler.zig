const std = @import("std");
const sdl = @cImport(@cInclude("SDL2/SDL.h"));

const math = @import("../core/math/math.zig");

const constants = @import("../core/constants.zig");
const float = constants.FLOAT;
const Vec3 = @import("../core/math/math.zig").Vec3;
const Vec3f = Vec3(float);

const Event = sdl.SDL_Event;
const PositionHandler = @import("transform.zig").PositionHandler;

pub const EventHandler = packed struct {
    noop: bool = false,
    keyboard_movement: bool = false,
    mouse_movement: bool = false,

    width: usize = 400,
    height: usize = 400,

    const Self = @This();

    pub fn handle_event(self: Self, event: sdl.SDL_Event, position: *const PositionHandler) void {
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
                    sdl.SDLK_LSHIFT => position.translate(Vec3f.init(0, -1, 0)),
                    sdl.SDLK_SPACE => position.translate(Vec3f.init(0, 1, 0)),
                    else => {},
                }
            },
            sdl.SDL_MOUSEMOTION => if (self.mouse_movement) {
                const x: i32, const y: i32 = .{ event.motion.xrel, event.motion.yrel };
                position.rotate(Vec3f.init(
                    (180 * @as(float, @floatFromInt(y)) / @as(f32, @floatFromInt(self.height))),
                    (180 * @as(float, @floatFromInt(x)) / @as(f32, @floatFromInt(self.width))),
                    0,
                ));
            },
            else => {}, // Ignore other events
        }
    }
};
