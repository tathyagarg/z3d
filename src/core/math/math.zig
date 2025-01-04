const std = @import("std");
const sqrt = std.math.sqrt;

pub const utilslib = @import("utils.zig");
pub const appropriate_division = utilslib.appropriate_division;
pub const PixelComputationOptions = utilslib.PixelComputationOptions;
pub const Bounds = utilslib.Bounds;

// A 3 dimensional vector
// Can be used to represent direction, a point, etc.
pub const Vec3lib = @import("vec3.zig");
pub const Vec3 = Vec3lib.Vec3;
pub const Vec3i32 = Vec3lib.Vec3i32;
pub const Vec3f32 = Vec3lib.Vec3f32;
pub const edge_function = Vec3lib.edge_function;

// A 4x4 matrix
pub const Mat4lib = @import("mat4.zig");
pub const Mat4 = Mat4lib.Mat4;
pub const Mat4f32 = Mat4lib.Mat4f32;

// A 2 dimensional vector
// Can be used to represent location on the screen (pixel coords)
pub const Vec2lib = @import("vec2.zig");
pub const Vec2 = Vec2lib.Vec2;
pub const Vec2f32 = Vec2lib.Vec2f32;
pub const Vec2i32 = Vec2lib.Vec2i32;

pub const INCH_TO_MM = 25.4;
pub const DEG_TO_RAD: f32 = std.math.pi / @as(f32, @floatFromInt(180));

pub inline fn solve_quadratic(a: f32, b: f32, c: f32, x0: *f32, x1: *f32) bool {
    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return false;
    } else if (discriminant == 0) {
        x0.* = -0.5 * b / a;
        x1.* = x0.*;
    } else {
        const q = if (b > 0) -0.5 * (b + sqrt(discriminant)) else -0.5 * (b - sqrt(discriminant));

        x0.* = q / a;
        x1.* = c / q;
    }
    if (x0.* > x1.*) {
        const temp = x1.*;
        x1.* = x0.*;
        x0.* = temp;
    }

    return true;
}

pub fn rgb_to_vec3f(comptime T: type, r: u8, g: u8, b: u8) Vec3(T) {
    return Vec3(T).init(
        @as(T, @floatFromInt(r)) / 255,
        @as(T, @floatFromInt(g)) / 255,
        @as(T, @floatFromInt(b)) / 255,
    );
}
