const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = @import("../../core/math/math.zig").Vec3;
const Vec3f = Vec3(float);

pub const MaterialType = enum {
    DIFFUSE_AND_GLOSSY,
    REFLECTION_AND_REFRACTION,
    REFLECTION,
};

pub const Material = struct {
    material_type: MaterialType = .DIFFUSE_AND_GLOSSY,
    ior: float = 1.3,
    kd: float = 0.8,
    ks: float = 0.2,
    diffuse_color: Vec3f = Vec3f.diagonal(0.2),
    specular_exponent: float = 25,
};
