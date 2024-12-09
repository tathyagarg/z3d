const math = @import("../../core/math/math.zig");
const transform = @import("../transform/transform.zig");
const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);
const position = transform.position;

pub const PhysicsEngine = struct {
    position: *position.PositionHandler,
    velocity: *Vec3f,
    force: *Vec3f,
    mass: *float,

    const Self = @This();

    pub fn init(position_handler: *position.PositionHandler, options: struct {
        velocity: ?Vec3f = null,
        force: ?Vec3f = null,
        mass: ?float = null,
    }) Self {
        var velocity = options.velocity orelse Vec3f.zero();
        var force = options.force orelse Vec3f.zero();
        var mass = options.mass orelse 0;

        return Self{
            .position = position_handler,
            .velocity = &velocity,
            .force = &force,
            .mass = &mass,
        };
    }
};
