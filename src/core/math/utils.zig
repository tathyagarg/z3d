const constants = @import("../constants.zig");
const INT_DIVISION = @import("../constants.zig").INT_DIVISION;

pub fn appropriate_division(comptime T: type, numerator: T, denominator: T) T {
    return switch (@typeInfo(T)) {
        .int => INT_DIVISION(T, numerator, denominator),
        .float => numerator / denominator,
        else => unreachable,
    };
}

pub const PixelComputationOptions = struct {
    bottom: f32,
    left: f32,
    top: f32,
    right: f32,
    near: f32, // near clipping plane
    screen_width: u32 = constants.SCREEN_WIDTH,
    screen_height: u32 = constants.SCREEN_HEIGHT,
};

pub fn Bounds(comptime T: type) type {
    return struct {
        minimum: T,
        maximum: T,
    };
}
