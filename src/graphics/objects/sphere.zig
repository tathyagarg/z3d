const Vec3 = @import("../../core/math/all.zig").Vec3f32;
const Vec2 = @import("../../core/math/all.zig").Vec2f32;
const Ray = @import("../ray.zig").Ray;
const ArrayList = @import("std").ArrayList;
const Material = @import("../material.zig").Material;

const solve_quadratic = @import("../../core/math/all.zig").solve_quadratic;

pub const Sphere = struct {
    center: Vec3,
    radius: f32,
    radius_sqr: f32 = undefined,
    material: Material,

    const Self = @This();

    pub fn init(c: Vec3, r: f32, material: Material) Self {
        return Self{
            .center = c,
            .radius = r,
            .radius_sqr = r * r,
            .material = material,
        };
    }

    pub fn intersects(self: Self, ray: Ray, t: *f32) bool {
        const L = ray.origin.subtract(self.center);
        const a = ray.direction.dot(ray.direction);
        const b = 2 * ray.direction.dot(L);
        const c = L.dot(L) - self.radius_sqr;

        var t0: f32 = undefined;
        var t1: f32 = undefined;

        if (!solve_quadratic(a, b, c, &t0, &t1)) return false;

        if (t0 < 0) t0 = t1;
        if (t0 < 0) return false;

        t.* = t0;
        return true;
    }

    pub fn get_surface_props(
        self: Self,
        P: *const Vec3,
        I: *const Vec3,
        index: usize,
        uv: *Vec2,
        normal: *Vec3,
        st: *Vec2,
    ) void {
        normal.* = (P.subtract(self.center)).normalize();
        _ = .{ I, index, uv, st };
    }
};
