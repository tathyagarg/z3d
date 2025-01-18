const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = @import("../../core/math/math.zig").Vec3;
const Vec3f = Vec3(float);

const RGB = @import("rgb.zig").RGB;

const Image = @import("../images/images.zig").Image;

pub const MaterialType = enum {
    DIFFUSE_AND_GLOSSY,
    REFLECTION_AND_REFRACTION,
    REFLECTION,
};

pub const Texture = union(enum) {
    SOLID_COLOR: RGB,
    TEXTURE_FILE: Image, // file path
};

pub const Material = struct {
    material_type: MaterialType = .DIFFUSE_AND_GLOSSY,
    ior: float = 1.3,
    kd: float = 0.8,
    ks: float = 0.2,
    texture: Texture,
    specular_exponent: float = 25,
};
