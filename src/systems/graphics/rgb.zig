const float = @import("../../core/constants.zig").FLOAT;
const math = @import("../../core/math/math.zig");
const Vec3 = math.Vec3;
const Vec3f = Vec3(float);

pub const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,

    pub fn vec_to_rgb(vec: Vec3f) RGB {
        return RGB{
            .r = @as(u8, @intFromFloat(vec.x * 255)),
            .g = @as(u8, @intFromFloat(vec.y * 255)),
            .b = @as(u8, @intFromFloat(vec.z * 255)),
        };
    }

    pub fn rgb_to_vec(self: RGB) Vec3f {
        return Vec3f.init(
            @as(float, @floatFromInt(self.r)) / 255,
            @as(float, @floatFromInt(self.g)) / 255,
            @as(float, @floatFromInt(self.b)) / 255,
        );
    }
};
