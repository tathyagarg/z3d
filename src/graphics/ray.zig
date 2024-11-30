const Vec3 = @import("../core/math/primitives.zig").Vec3;

pub const Ray = struct {
    origin: Vec3,
    direction: Vec3,
};
