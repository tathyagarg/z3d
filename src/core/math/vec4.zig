const std = @import("std");
const math = std.math;

/// A vec4 is a mathematical vector of form:
/// v = [w x y z]
pub const Vec4 = struct {
    x: f32,
    y: f32,
    z: f32,
    w: f32,

    pub fn negate(self: Vec4) Vec4 {
        return Vec4{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
            .w = -self.w,
        };
    }

    pub fn add(self: Vec4, other: Vec4) Vec4 {
        return Vec4{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
            .w = self.w + other.w,
        };
    }

    pub fn subtract(self: Vec4, other: Vec4) Vec4 {
        return self.add(other.negate());
    }

    pub fn multiply(self: Vec4, scalar: f32) Vec4 {
        return Vec4{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
            .w = self.w * scalar,
        };
    }

    /// Divides a Vec4 by a scalar quantity.
    /// If the scalar quantity is 0, it throws an error.
    pub fn strict_divide(self: Vec4, scalar: f32) Vec4 {
        return Vec4{
            .x = self.x / scalar,
            .y = self.y / scalar,
            .z = self.z / scalar,
            .w = self.w / scalar,
        };
    }

    /// Divides a Vec4 by a scalar quantity.
    /// If the scalar quantity is 0, it returns the vector back.
    pub fn divide(self: Vec4, scalar: f32) Vec4 {
        if (scalar == 0) {
            return self;
        }

        return self.strict_divide(scalar);
    }

    pub fn dot_product(self: Vec4, other: Vec4) f32 {
        return (self.w * other.w) + (self.x * other.x) + (self.y * other.y) + (self.z * other.z);
    }

    pub fn magnitude(self: Vec4) f32 {
        return math.sqrt((self.w * self.w) + (self.x * self.x) + (self.y * self.y) + (self.z * self.z));
    }

    pub fn normalize(self: Vec4) Vec4 {
        return self.divide(self.magnitude());
    }

    pub fn distance(self: Vec4, other: Vec4) f32 {
        return math.sqrt(math.pow(f32, self.w - other.w, 2) +
            math.pow(f32, self.x - other.x, 2) +
            math.pow(f32, self.y - other.y, 2) +
            math.pow(f32, self.z - other.z, 2));
    }
};
