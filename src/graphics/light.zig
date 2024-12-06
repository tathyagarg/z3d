const float = @import("../core/constants.zig").FLOAT;

const Vec3 = @import("../core/math/all.zig").Vec3;
const Vec3f = Vec3(float);

pub const Light = struct {
    position: Vec3f,
    intensity: Vec3f,
};
