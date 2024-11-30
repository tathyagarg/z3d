const Vec3 = @import("../core/math/primitives.zig").Vec3;

pub const Triangle = struct {
    points: struct { a: Vec3, b: Vec3, c: Vec3 },
    normal_vec: ?Vec3 = null,

    pub fn normal(self: Triangle) Vec3 {
        return self.normal_vec orelse {
            const AB = self.points.b.subtract(self.points.a); // Edge 1
            const AC = self.points.c.subtract(self.points.a); // Edge 2

            const unnormalized_normal_vec = AB.cross_product(AC);
            const normal_vec = unnormalized_normal_vec.normalize();

            self.normal_vec = normal_vec;
            return normal_vec;
        };
    }
};
