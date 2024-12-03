pub const CANVAS_WIDTH: f32 = 2;
pub const CANVAS_HEIGHT: f32 = 2;

pub const SCREEN_WIDTH = 400;
pub const SCREEN_HEIGHT = 225;

pub const IS_RIGHT_HANDED = true;
pub fn INT_DIVISION(comptime T: type, numerator: T, denominator: T) T {
    return @divTrunc(numerator, denominator);
}
