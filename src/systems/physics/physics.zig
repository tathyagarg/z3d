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

    damping: float = 0.1,

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
        // self.position.translate(Vec3f.init(0, 0, -1));
        self.position.translate(self.velocity);

        const resulting_acc = self.acceleration.add(self.force.multiply(self.inv_mass));

        self.velocity = self.velocity.add(resulting_acc);
        self.velocity = self.velocity.multiply(self.damping);
        // self.force.* = Vec3f.zero();
    }
};
