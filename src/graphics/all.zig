pub const utilslib = @import("utils.zig");
pub const FitResolutionGate = utilslib.FitResolutionGate;
pub const compute_screen_coordinates = utilslib.compute_screen_coordinates;

pub const types = @import("types/all.zig");

const math = @import("../core/math/all.zig");
const Mat4f32 = math.Mat4f32;
const DEG_TO_RAD = math.DEG_TO_RAD;

pub fn projection_matrix_factory(
    angle_of_view: f32,
    near: f32,
    far: f32,
) fn () Mat4f32 {
    const scale = 1 / @tan(angle_of_view * 0.5 * DEG_TO_RAD);

    const Factory = struct {
        fn factory() Mat4f32 {
            return Mat4f32{ .m = [4][4]f32{
                .{ scale, 0, 0, 0 },
                .{ 0, scale, 0, 0 },
                .{ 0, 0, -far / (far - near), -1 },
                .{ 0, 0, -far * near / (far - near), 0 },
            } };
        }
    };

    return Factory.factory;
}
