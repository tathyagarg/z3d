const Vec3 = @import("../core/math/all.zig").Vec3f32;
const Vec2 = @import("../core/math/all.zig").Vec2f32;
const Object = @import("objects/object.zig").Object;
const std = @import("std");
const ArrayList = std.ArrayList;

const sqrt = std.math.sqrt;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    const Self = @This();

    pub fn at(self: Self, t: f32) Vec3 {
        return self.origin.add(self.direction.multiply(t));
    }

    pub fn triangle_intersect(
        self: Self,
        v0: Vec3,
        v1: Vec3,
        v2: Vec3,
        t: *f32,
        u: *f32,
        v: *f32,
    ) bool {
        const edge1 = v1.subtract(v0);
        const edge2 = v2.subtract(v0);

        const pvec = self.direction.cross(edge2);
        const det = edge1.dot(pvec);
        if (det <= 0) return false;

        const tvec = self.origin.subtract(v0);
        u.* = tvec.dot(pvec);
        if (u.* < 0 or u.* > det) return false;

        const qvec = tvec.cross(edge1);
        v.* = self.direction.dot(qvec);
        if (v.* < 0 or (u.* + v.*) > det) return false;

        const inv_det = 1 / det;
        t.* = edge2.dot(qvec) * inv_det;
        u.* *= inv_det;
        v.* *= inv_det;

        return true;
    }

    pub fn reflection(self: Self, normal: Vec3) Vec3 {
        return self.direction.subtract(
            normal.multiply(
                normal.dot(self.direction) * 2,
            ),
        );
    }

    pub fn refraction(self: Self, normal: Vec3, ior: f32) Vec3 {
        var cosi = std.math.clamp(self.direction.dot(normal), -1, 1);
        var etai: f32 = 1;
        var etat = ior;

        var n = normal;

        if (cosi < 0) {
            cosi = -cosi;
        } else {
            const temp = etat;
            etat = etai;
            etai = temp;

            n = normal.negate();
        }

        const eta: f32 = etai / etat;
        const k = 1 - eta * eta * (1 - cosi * cosi);

        const res = if (k < 0) Vec3.zero() else self.direction
            .multiply(eta)
            .add(n.multiply(eta * cosi - sqrt(k)));
        return res;
    }

    /// ior is the mateural refractive index
    /// kr is the amount of light reflected
    pub fn fresnel(self: Self, normal: Vec3, ior: f32, kr: *f32) void {
        var cosi = std.math.clamp(self.direction.dot(normal), -1, 1);
        var etai: f32 = 1;
        var etat = ior;

        if (cosi > 0) {
            const temp = etai;
            etai = etat;
            etat = temp;
        }

        // Snell's law time!
        const sint = etai / etat * sqrt(@max(0, 1 - cosi * cosi));
        if (sint >= 1) {
            kr.* = 1;
        } else {
            const cost = sqrt(@max(0, 1 - sint * sint));
            cosi = @abs(cosi);

            const Rs = ((etat * cosi) - (etai * cost)) / ((etat * cosi) + (etai * cost));
            const Rp = ((etai * cosi) - (etat * cost)) / ((etai * cosi) + (etat * cost));

            kr.* = (Rs * Rs + Rp * Rp) / 2;
        }
    }

    pub fn trace(
        self: Self,
        objects: *const ArrayList(Object),
        t_near: *f32,
        index: *usize,
        uv: *Vec2,
        hit_object: *Object,
        x: usize,
        y: usize,
    ) bool {
        hit_object.* = undefined;
        var hit = false;

        for (0..objects.items.len) |k| {
            var t_near_k = std.math.inf(f32);
            var index_k: usize = undefined;
            var uv_k: Vec2 = undefined;
            const intersects = switch (objects.items[k]) {
                .sphere => objects.items[k].sphere.intersects(self, &t_near_k),
                .mesh_triangle => objects.items[k].mesh_triangle.intersects(self, &t_near_k, &index_k, &uv_k),
            };

            if (intersects and t_near_k < t_near.*) {
                hit_object.* = objects.*.items[k];
                t_near.* = t_near_k;
                index.* = index_k;
                uv.* = uv_k;

                hit = true;
            }
            if (x == 320 and y == 218)
                std.debug.print("BAKCHODI: {d} {d} {d} {d}\n", .{
                    t_near.*,
                    index.*,
                    @as(u1, @intFromBool(intersects)),
                    t_near_k,
                });
        }

        return hit;
    }
};
