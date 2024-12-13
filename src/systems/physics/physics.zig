const std = @import("std");
const math = @import("../../core/math/math.zig");
const transform = @import("../transform/transform.zig");
const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);
const position = transform.position;

pub const PhysicsEngine = struct {
    position: *const position.PositionHandler,
    velocity: Vec3f,
    force: Vec3f,
    acceleration: Vec3f,
    inv_mass: float,

    // Why 0.75? Feels kinda smooth
    damping: float = 0.75,

    const Self = @This();

    pub fn init(position_handler: *const position.PositionHandler, options: struct {
        velocity: ?Vec3f = null,
        force: ?Vec3f = null,
        acceleration: ?Vec3f = null,
        mass: ?float = null,
    }) Self {
        const velocity = options.velocity orelse Vec3f.zero();
        const force = options.force orelse Vec3f.zero();
        const acceleration = options.acceleration orelse Vec3f.zero();
        const mass = options.mass orelse 1;

        return Self{
            .position = position_handler,
            .velocity = velocity,
            .force = force,
            .acceleration = acceleration,
            .inv_mass = 1 / mass,
        };
    }

    pub fn update(self: *Self) !void {
        self.position.translate(self.velocity);

        const resulting_acc = self.acceleration.add(self.force.multiply(self.inv_mass));

        self.velocity = self.velocity.add(resulting_acc);
        self.velocity = self.velocity.multiply(self.damping);

        self.clear_force();
    }

    pub fn apply_gravity(self: *Self, gravity: Vec3f) void {
        self.add_force(gravity.multiply(1 / self.inv_mass));
    }

    pub fn add_force(self: *Self, force: Vec3f) void {
        self.force = self.force.add(force);
    }

    pub fn clear_force(self: *Self) void {
        self.force = Vec3f.zero();
    }
};
