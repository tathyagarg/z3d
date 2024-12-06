pub const CANVAS_WIDTH: f32 = 2;
pub const CANVAS_HEIGHT: f32 = 2;

pub const SCREEN_WIDTH: usize = 400;
pub const SCREEN_HEIGHT: usize = 225;
pub const PIXEL_COUNT: usize = SCREEN_WIDTH * SCREEN_HEIGHT;

pub const IS_RIGHT_HANDED: bool = true;
pub fn INT_DIVISION(comptime T: type, numerator: T, denominator: T) T {
    return @divTrunc(numerator, denominator);
}

pub const FLOAT: type = f32;
