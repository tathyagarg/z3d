const math = @import("../../core/math/math.zig");
const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = Vec3(float);
const Vec2f = Vec2(float);

const Object = @import("objects/object.zig").Object;
const std = @import("std");
const ArrayList = std.ArrayList;

const sqrt = std.math.sqrt;

pub const Ray = struct {
    origin: Vec3f,
    direction: Vec3f,

    const Self = @This();

    pub fn at(self: Self, t: float) Vec3f {
        return self.origin.add(self.direction.multiply(t));
    }

    pub fn triangle_intersect(
        self: Self,
        v0: Vec3f,
        v1: Vec3f,
        v2: Vec3f,
        t: *float,
        u: *float,
        v: *float,
    ) bool {
        const e0 = v0.subtract(v1);
        const e1 = v0.subtract(v2);

        const pvec = self.direction.cross(e1);
        const det = e0.dot(pvec);

        if (@abs(det) < 1e-8) return false;

        const inv_det = 1.0 / det;
        const tvec = self.origin.subtract(v2);

        u.* = tvec.dot(pvec) * inv_det;
        if (u.* < 0 or u.* > 1) return false;

        const qvec = tvec.cross(e0);
        v.* = self.direction.dot(qvec) * inv_det;
        if (v.* < 0 or u.* + v.* > 1) return false;

        t.* = e1.dot(qvec) * inv_det;
        return t.* > 1e-8;
    }

    pub fn reflection(self: Self, normal: Vec3f) Vec3f {
        return self.direction.subtract(
            normal.multiply(
                normal.dot(self.direction) * 2,
            ),
        );
    }

    pub fn refraction(self: Self, normal: Vec3f, ior: float) Vec3f {
        var cosi: float = std.math.clamp(
            self.direction.dot(normal),
            @as(float, @floatFromInt(-1)),
            @as(float, @floatFromInt(1)),
        );
        var etai: float = 1;
        var etat: float = ior;

        var n: Vec3f = normal;

        if (cosi < 0) {
            cosi = -cosi;
        } else {
            const temp = etat;
            etat = etai;
            etai = temp;

            n = normal.negate();
        }

        const eta: float = etai / etat;
        const k: float = 1 - eta * eta * (1 - cosi * cosi);

        const res = if (k < 0) Vec3f.zero() else self.direction
            .multiply(eta)
            .add(n.multiply(eta * cosi - sqrt(k)));
        return res;
    }

    /// ior is the mateural refractive index
    /// kr is the amount of light reflected
    pub fn fresnel(self: Self, normal: Vec3f, ior: float, kr: *float) void {
        var cosi: float = std.math.clamp(
            self.direction.dot(normal),
            @as(float, @floatFromInt(-1)),
            @as(float, @floatFromInt(1)),
        );
        var etai: float = 1;
        var etat: float = ior;

        if (cosi > 0) {
            const temp = etai;
            etai = etat;
            etat = temp;
        }

        // Snell's law time!
        const sint: float = etai / etat * sqrt(@max(0, 1 - cosi * cosi));
        if (sint >= 1) {
            kr.* = 1;
        } else {
            const cost: float = sqrt(@max(0, 1 - sint * sint));
            cosi = @abs(cosi);

            const Rs: float = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
            const Rp: float = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));

            kr.* = (Rs * Rs + Rp * Rp) / 2;
        }
    }

    pub fn trace(
        self: Self,
        objects: *const ArrayList(Object),
        t_near: *float,
        index: *usize,
        uv: *Vec2f,
        hit_object: *Object,
    ) bool {
        var hit: bool = false;

        for (objects.items) |obj| {
            var t_near_k: float = std.math.inf(float);
            var index_k: usize = undefined;
            var uv_k: Vec2f = undefined;

            // const intersects = switch (obj) {
            //     .sphere => |s| s.intersects(self, &t_near_k),
            //     .mesh_triangle => |m| m.intersects(self, &t_near_k, &index_k, &uv_k),
            // };
            const intersects = self.check_intersects(&t_near_k, &index_k, &uv_k, obj);

            if (intersects and t_near_k < t_near.*) {
                hit_object.* = obj;
                t_near.* = t_near_k;
                index.* = index_k;
                uv.* = uv_k;

                hit = true;
            }
        }

        return hit;
    }

    inline fn check_intersects(
        self: Self,
        t_near_k: *float,
        index_k: *usize,
        uv_k: *Vec2f,
        obj: Object,
    ) bool {
        return switch (obj) {
            .sphere => |s| s.intersects(self, t_near_k),
            .mesh_triangle => |m| m.intersects(self, t_near_k, index_k, uv_k),
        };
    }
};
