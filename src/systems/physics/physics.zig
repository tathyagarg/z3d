const std = @import("std");
const math = @import("../../core/math/math.zig");
const position = @import("../transform.zig");
const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);

const ArrayList = std.ArrayList;

const Object = @import("../graphics/objects/object.zig").Object;

pub const GRAVITY = Vec3f.init(0, -2e-1, 0);

pub const PhysicsEngine = struct {
    object: Object,
    velocity: Vec3f,
    force: Vec3f,
    acceleration: Vec3f,
    inv_mass: float,

    pos_handler: position.PositionHandler,
    obj_id: usize,

    // Why 0.75? Feels kinda smooth
    // Scratch that, smoothness went away went object was brought closer from z = -50
    damping: float = 0.5,
    resting_force: Vec3f = Vec3f.zero(),

    const Self = @This();

    pub fn init(
        object: Object,
        options: struct {
            velocity: Vec3f = Vec3f.zero(),
            force: Vec3f = Vec3f.zero(),
            acceleration: Vec3f = Vec3f.zero(),
            mass: float = 1,
        },
    ) Self {
        return Self{
            .object = object,
            .velocity = options.velocity,
            .force = options.force,
            .acceleration = options.acceleration,
            .inv_mass = 1 / options.mass,
            .pos_handler = object.get_position_handler(),
            .obj_id = object.get_id(),
        };
    }

    pub fn update(self: *Self, objects: *ArrayList(Object)) !void {
        var collision = false;
        var distance: Vec3f = undefined;

        for (objects.items) |object| {
            if (self.obj_id == object.get_id()) continue;

            const res = self.object.intersects(object);
            if (res[0]) {
                collision = true;
                distance = self.pos_handler.get_distance_from(res[1]);
            }
        }

        const offset = switch (self.object) {
            .sphere => |s| s.radius,
            else => 0,
        };

        if (collision and @abs(distance.norm() - offset) > 0.01) {
            self.pos_handler.translate(Vec3f.init(0, 0.01, 0));
        }
        if (!collision) {
            self.force = self.force.add(self.resting_force);

            const resulting_acc = self.acceleration.add(
                self.force.multiply(self.inv_mass),
            );

            self.velocity = self.velocity.add(resulting_acc);
            self.velocity = self.velocity.multiply(self.damping);
            self.pos_handler.translate(self.velocity);

            self.clear_force();
        }
    }

    pub fn apply_gravity(self: *Self, gravity: ?Vec3f) void {
        const gravity_val = gravity orelse GRAVITY;
        self.add_force(gravity_val.multiply(1 / self.inv_mass));
        self.resting_force = self.resting_force.add(gravity_val);
    }

    pub fn add_force(self: *Self, force: Vec3f) void {
        self.force = self.force.add(force);
    }

    pub fn clear_force(self: *Self) void {
        self.force = Vec3f.zero();
    }
};
