const std = @import("std");
const sdl = @cImport(@cInclude("SDL2/SDL.h"));

const math = @import("../core/math/math.zig");
const transform = @import("../systems/transform.zig");
const float = @import("../core/constants.zig").FLOAT;
const PositionHandler = transform.PositionHandler;
const SinglePointHandler = transform.SinglePointHandler;
const EventHandler = @import("../systems/event_handler.zig").EventHandler;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);

pub const Camera = struct {
    position: *const PositionHandler,
    event_handler: *const EventHandler = &EventHandler{
        .keyboard_movement = true,
        .mouse_movement = true,
    },

    const Self = @This();

    pub fn get_direction(self: Self, x: float, y: float) Vec3f {
        // Facing -z (0 0 -1):  x  y -1
        // Facing z  (0 0 1) :  x  y  1
        // Facing -x (-1 0 0): -1  y  x
        // Facing x  (1 0 0) :  1  y  x
        // Facing -y (0 -1 0):  x -1  y
        // Facing y  (0 1 0) :  x  1  y
        _ = .{ self, x, y };

        const a = self.position.get_direction().x * math.DEG_TO_RAD;
        const b = self.position.get_direction().y * math.DEG_TO_RAD;
        const c = self.position.get_direction().z * math.DEG_TO_RAD;

        // "How did you come to these formulas?" you may ask
        // I have no fucking clue
        // I just typed it and it worked
        // Update: no it fucking didnt
        // Update 2: Works!
        return Vec3f.init(
            (x * @cos(b) * @cos(c)) + (y * (@sin(a) * @sin(b) * @cos(c) - @cos(a) * @sin(c))) + (1 * (@cos(a) * @sin(b) * @cos(c) + @sin(a) * @sin(c))),
            (x * @cos(b) * @sin(c)) + (y * (@sin(a) * @sin(b) * @sin(c) + @cos(a) * @cos(c))) + (1 * (@cos(a) * @sin(b) * @sin(c) - @sin(a) * @cos(c))),
            -(x * @sin(b)) + (y * @sin(a) * @cos(b)) + (1 * @cos(a) * @cos(b)),
        );
    }

    pub fn handle_event(self: Self, event: sdl.SDL_Event) void {
        self.event_handler.handle_event(event, self.position);
    }
};
