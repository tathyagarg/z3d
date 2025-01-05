const math = @import("../../../core/math/math.zig");
const float = @import("../../../core/constants.zig").FLOAT;
const physics = @import("../../physics/physics.zig");
const position = @import("../../transform.zig");

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = math.Vec3(float);
const Vec2f = math.Vec2(float);

const Ray = @import("../ray.zig").Ray;
const ArrayList = @import("std").ArrayList;
const Material = @import("../material.zig").Material;

const solve_quadratic = math.solve_quadratic;

pub const Sphere = struct {
    position: position.PositionHandler,
    radius: float,
    radius_sqr: float = undefined,

    material: *const Material,
    physics: ?*physics.PhysicsEngine = null,

    const Self = @This();

    pub fn init(c: *Vec3f, r: float, material: *const Material) Self {
        const position_handler = position.PositionHandler{
            .single = position.SinglePointHandler{
                .point = c,
                .is_static = false,
            },
        };
        return Self{
            .position = position_handler,
            .radius = r,
            .radius_sqr = r * r,
            .material = material,
        };
    }

    pub fn intersects(self: Self, ray: Ray, t: *float) bool {
        // If the ray is going in the opposite direction of the sphere, return false
        // if ((self.position.single.point.x < ray.origin.x and ray.direction.x > 0) or
        //     (self.position.single.point.y < ray.origin.y and ray.direction.y > 0) or
        //     (self.position.single.point.z < ray.origin.z and ray.direction.z > 0) or
        //     (self.position.single.point.x > ray.origin.x and ray.direction.x < 0) or
        //     (self.position.single.point.y > ray.origin.y and ray.direction.y < 0) or
        //     (self.position.single.point.z > ray.origin.z and ray.direction.z < 0)) return false;

        const origin: Vec3f = ray.origin.subtract(self.position.single.point.*);
        const a: float = ray.direction.dot(ray.direction);
        const b: float = 2 * ray.direction.dot(origin);
        const c: float = origin.dot(origin) - self.radius_sqr;

        const disc = b * b - 4 * a * c;
        if (disc < 0) return false;

        var t0: float = undefined;
        var t1: float = undefined;

        if (!solve_quadratic(a, b, c, &t0, &t1)) return false;

        if (t0 < 0) t0 = t1;
        if (t0 < 0) return false;

        t.* = t0;
        return true;
    }

    pub inline fn get_surface_props(
        self: Self,
        P: *const Vec3f,
        normal: *Vec3f,
    ) void {
        normal.* = (P.subtract(self.position.single.point.*)).normalize();
    }
};
