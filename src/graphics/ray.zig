const Vec3 = @import("../core/math/primitives.zig").Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,

    pub fn at(self: Ray, t: f32) Vec3 {
        return self.origin.add(self.direction.multiply(t));
    }
};
