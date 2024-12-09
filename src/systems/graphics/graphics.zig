pub const utilslib = @import("utils.zig");
pub const FitResolutionGate = utilslib.FitResolutionGate;
pub const compute_screen_coordinates = utilslib.compute_screen_coordinates;
pub const RayCastingOptions = utilslib.RayCastingOptions;
pub const cast_ray = utilslib.cast_ray;

const math = @import("../../core/math/math.zig");
const float = @import("../../core/constants.zig").FLOAT;
const Mat4f = math.Mat4(float);
const Vec3f = math.Vec3(float);
const DEG_TO_RAD = math.DEG_TO_RAD;

pub fn projection_matrix_factory(
    angle_of_view: float,
    near: float,
    far: float,
) fn () Mat4f {
    const scale = 1 / @tan(angle_of_view * 0.5 * DEG_TO_RAD);

    const Factory = struct {
        fn factory() Mat4f {
            return Mat4f{ .m = [4][4]f32{
                .{ scale, 0, 0, 0 },
                .{ 0, scale, 0, 0 },
                .{ 0, 0, -far / (far - near), -1 },
                .{ 0, 0, -far * near / (far - near), 0 },
            } };
        }
    };

    return Factory.factory;
}

pub const objects = @import("objects/object.zig");
pub const material = @import("material.zig");
pub const Ray = @import("ray.zig").Ray;

pub const Light = struct {
    position: Vec3f,
    intensity: Vec3f,
};
