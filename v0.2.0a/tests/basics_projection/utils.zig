pub const Vec3 = @import("z3d").math.Vec3f32;

// These Vec3i32s represent the corners of a cube in 3D world space.
pub const corners = [8]Vec3{
    Vec3.init(1, -1, -5),
    Vec3.init(1, -1, -3),
    Vec3.init(1, 1, -5),
    Vec3.init(1, 1, -3),
    Vec3.init(-1, -1, -5),
    Vec3.init(-1, -1, -3),
    Vec3.init(-1, 1, -5),
    Vec3.init(-1, 1, -3),
};
