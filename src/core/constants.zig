pub const IS_RIGHT_HANDED: bool = true;
pub fn INT_DIVISION(comptime T: type, numerator: T, denominator: T) T {
    return @divTrunc(numerator, denominator);
}

pub const FLOAT: type = f32;
