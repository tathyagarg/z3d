const constants = @import("../constants.zig");
const sqrt = @import("std").math.sqrt;

pub fn Vec3(comptime T: type) type {
    return packed struct {
        x: T,
        y: T,
        z: T,

        const Self = @This();

        pub fn zero() Self {
            return Self{ .x = 0, .y = 0, .z = 0 };
        }

        pub fn diagonal(value: T) Self {
            return Self{ .x = value, .y = value, .z = value };
        }

        pub fn init(x: T, y: T, z: T) Self {
            return Self{ .x = x, .y = y, .z = z };
        }

        pub fn negate(self: Self) Self {
            return Self{
                .x = -self.x,
                .y = -self.y,
                .z = -self.z,
            };
        }

        /// Returns the x-projection of a point
        /// x_proj = p.x / -p.z
        /// x_proj is in the range [-1, 1] and is in screen space
        pub fn x_projection(self: Self) error{ZisZero}!T {
            if (self.z == 0) return error.ZisZero;

            return switch (@typeInfo(T)) {
                .int => @divTrunc(self.x, -self.z),
                .float => self.x / -self.z,
                else => unreachable,
            };
        }

        /// Returns the y-projection of a point
        /// y_proj = p.y / -p.z
        /// y_proj is in the range [-1, 1] and is in screen space
        pub fn y_projection(self: Self) error{ZisZero}!T {
            if (self.z == 0) return error.ZisZero;

            return switch (@typeInfo(T)) {
                .int => @divTrunc(self.y, -self.z),
                .float => self.y / -self.z,
                else => unreachable,
            };
        }

        /// Returns the remapped x-projection of a point
        /// x_proj_remap = (1 + (p.x / -p.z)) / 2
        /// x_proj_remap is in the range [0, 1] and is in NDC space
        pub fn ndc_x_projection(self: Self) error{ZisZero}!T {
            const x_proj = try self.x_projection();
            return (1 + x_proj) / 2;
        }

        /// Returns the remapped y-projection of a point
        /// y_proj_remap = (1 + (p.y / -p.z)) / 2
        /// y_proj_remap is in the range [0, 1] and is in NDC space
        pub fn ndc_y_projection(self: Self) error{ZisZero}!T {
            const y_proj = try self.y_projection();
            return (1 + y_proj) / 2;
        }

        /// Returns the x-projection of a point in raster space
        /// x_proj_raster = ((1 + (p.x / -p.z)) / 2) * SCREEN_WIDTH
        /// x_proj_raster is in the range [0, SCREEN_WIDTH] and is in raster space
        pub fn raster_x_projection(self: Self) error{ZisZero}!T {
            const x_proj_ndc = try self.ndc_x_projection();
            return x_proj_ndc * constants.SCREEN_WIDTH;
        }

        /// Returns the y-projection of a point in raster space
        /// y_proj_raster = ((1 + (p.y / -p.z)) / 2) * SCREEN_HEIGHT
        /// y_proj_raster is in the range [0, SCREEN_HEIGHT] and is in raster space
        pub fn raster_y_projection(self: Self) error{ZisZero}!T {
            const y_proj_ndc = try self.ndc_y_projection();
            return y_proj_ndc * constants.SCREEN_HEIGHT;
        }

        pub fn add(self: Self, other: Self) Self {
            return Self{
                .x = self.x + other.x,
                .y = self.y + other.y,
                .z = self.z + other.z,
            };
        }

        pub fn subtract(self: Self, other: Self) Self {
            return self.add(other.negate());
        }

        /// Find the cross product of the given vectors
        /// For two vectors `a` and `b`, the components of the cross product `a x b` are given by:
        /// (a x b).x = (a.y * b.z) - (a.z * b.y)
        /// (a x b).y = (a.z * b.x) - (a.x * b.z)
        /// (a x b).z = (a.x * b.y) - (a.y * b.z)
        pub fn cross(self: Self, other: Self) Self {
            return Self{
                .x = (self.y * other.z) - (self.z * other.y),
                .y = (self.z * other.x) - (self.x * other.z),
                .z = (self.x * other.y) - (self.y * other.x),
            };
        }

        /// Changes the coordinate system from the:
        /// - Right handed CS to Left handed CS
        /// - Left handed CS to Right handed CS
        pub fn change_handedness(self: Self) Self {
            return Self{ .x = -self.x, .y = self.y, .z = self.z };
        }

        /// Gets the length of the vector, also referred to as the norm or magnitude of the vector
        /// The norm of a vector `a` is given by:
        /// ||a|| = sqrt(a.x^2 + a.y^2 + a.z^2)
        pub fn norm(self: Self) Self {
            return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
        }

        pub fn normalize(self: Self) Self {
            return self;
        }
    };
}

// Preset Vec3 types
pub const Vec3i32 = Vec3(i32);
pub const Vec3f32 = Vec3(f32);
