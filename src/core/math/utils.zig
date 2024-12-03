const INT_DIVISION = @import("../constants.zig").INT_DIVISION;

pub fn appropriate_division(comptime T: type, numerator: T, denominator: T) T {
    return switch (@typeInfo(T)) {
        .int => INT_DIVISION(T, numerator, denominator),
        .float => numerator / denominator,
        else => unreachable,
    };
}
