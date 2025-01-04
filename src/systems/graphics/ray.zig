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
        const edge1: Vec3f = v1.subtract(v0);
        const edge2: Vec3f = v2.subtract(v0);

        const pvec: Vec3f = self.direction.cross(edge2);
        const det: float = edge1.dot(pvec);
        if (det <= 0) return false;

        const tvec: Vec3f = self.origin.subtract(v0);
        u.* = tvec.dot(pvec);
        if (u.* < 0 or u.* > det) return false;

        const qvec: Vec3f = tvec.cross(edge1);
        v.* = self.direction.dot(qvec);
        if (v.* < 0 or (u.* + v.*) > det) return false;

        const inv_det: float = 1 / det;
        t.* = edge2.dot(qvec) * inv_det;
        u.* *= inv_det;
        v.* *= inv_det;

        return true;
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
        hit_object.* = undefined;
        var hit: bool = false;

        for (0..objects.items.len) |k| {
            var t_near_k: float = std.math.inf(float);
            var index_k: usize = undefined;
            var uv_k: Vec2f = undefined;
            const intersects = switch (objects.items[k]) {
                .sphere => |s| s.intersects(self, &t_near_k),
                .mesh_triangle => |m| m.intersects(self, &t_near_k, &index_k, &uv_k),
            };

            if (intersects and t_near_k < t_near.*) {
                hit_object.* = objects.items[k];
                t_near.* = t_near_k;
                index.* = index_k;
                uv.* = uv_k;

                hit = true;
            }
        }

        return hit;
    }
};
