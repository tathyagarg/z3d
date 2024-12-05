const Vec3 = @import("../core/math/all.zig").Vec3f32;

pub const Light = struct {
    position: Vec3,
    intensity: Vec3,
};
