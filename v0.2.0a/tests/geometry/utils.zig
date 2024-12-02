pub const Vec3 = @import("z3d").math.Vec3(i8);

pub const vertices = [3]Vec3{
    Vec3.zero(),
    Vec3.init(0, 0, 1),
    Vec3.init(1, 0, 0),
};
