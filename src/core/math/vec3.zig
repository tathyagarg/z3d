const std = @import("std");
const math = std.math;

/// A vec3 is a representation of a 3D point of the form
/// v = [x y z]
pub const Vec3 = struct {
    x: f32,
    y: f32,
    z: f32,

    pub fn negate(self: Vec3) Vec3 {
        return Vec3{
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
        };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }

    pub fn subtract(self: Vec3, other: Vec3) Vec3 {
        return self.add(other.negate());
    }

    pub fn multiply(self: Vec3, scalar: f32) Vec3 {
        return Vec3{
            .x = self.x * scalar,
            .y = self.y * scalar,
            .z = self.z * scalar,
        };
    }

    /// Divides a Vec3 by a scalar quantity.
    /// If the scalar quantity is 0, it throws an error.
    pub fn strict_divide(self: Vec3, scalar: f32) Vec3 {
        return Vec3{
            .x = self.x / scalar,
            .y = self.y / scalar,
            .z = self.z / scalar,
        };
    }

    /// Divides a Vec3 by a scalar quantity.
    /// If the scalar quantity is 0, it returns the vector back.
    pub fn divide(self: Vec3, scalar: f32) Vec3 {
        if (scalar == 0) {
            return self;
        }

        return self.strict_divide(scalar);
    }

    pub fn dot_product(self: Vec3, other: Vec3) f32 {
        return (self.x * other.x) + (self.y * other.y) + (self.z * other.z);
    }

    pub fn cross_product(self: Vec3, other: Vec3) Vec3 {
        return Vec3{
            .x = (self.y * other.z) - (self.z * other.y),
            .y = (self.z * other.x) - (self.x * other.z),
            .z = (self.x * other.y) - (self.y * other.x),
        };
    }

    pub fn magnitude(self: Vec3) f32 {
        return math.sqrt((self.x * self.x) + (self.y * self.y) + (self.z * self.z));
    }

    pub fn normalize(self: Vec3) Vec3 {
        return self.divide(self.magnitude());
    }

    pub fn distance(self: Vec3, other: Vec3) f32 {
        return math.sqrt(math.pow(f32, self.x - other.x, 2) +
            math.pow(f32, self.y - other.y, 2) +
            math.pow(f32, self.z - other.z, 2));
    }
};
