const Vec3 = @import("../core/math/all.zig").Vec3f32;

pub const MaterialType = enum {
    DIFFUSE_AND_GLOSSY,
    REFLECTION_AND_REFRACTION,
    REFLECTION,
};

pub const Material = struct {
    material_type: MaterialType = .DIFFUSE_AND_GLOSSY,
    ior: f32 = 1.3,
    kd: f32 = 0.8,
    ks: f32 = 0.2,
    diffuse_color: Vec3 = Vec3.diagonal(0.2),
    specular_exponent: f32 = 25,
};
