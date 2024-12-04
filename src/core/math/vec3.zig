const std = @import("std");
const all = @import("all.zig");
const constants = @import("../constants.zig");

const Mat4 = all.Mat4;
const Vec2 = all.Vec2;
const appropriate_division = all.appropriate_division;
const PixelComputationOptions = all.PixelComputationOptions;

const math = @import("std").math;
const sqrt = math.sqrt;
const pow = math.pow;

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
            return appropriate_division(T, self.x, -self.z);
        }

        /// Returns the y-projection of a point
        /// y_proj = p.y / -p.z
        /// y_proj is in the range [-1, 1] and is in screen space
        pub fn y_projection(self: Self) error{ZisZero}!T {
            if (self.z == 0) return error.ZisZero;
            return appropriate_division(T, self.y, -self.z);
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

        pub fn multiply(self: Self, scalar: T) Self {
            return Self{
                .x = self.x * scalar,
                .y = self.y * scalar,
                .z = self.z * scalar,
            };
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
        pub fn norm(self: Self) T {
            return sqrt(self.x * self.x + self.y * self.y + self.z * self.z);
        }

        /// Normalizes a vector (gives a vector with length 1)
        /// The vector `a` is normalized to give vector `a_hat` through:
        /// a_hat = a / ||a||
        pub fn normalize(self: Self) Self {
            const len_sqr: T = pow(T, self.norm(), 2);
            if (len_sqr > 0) {
                const inv_len: T = 1 / sqrt(len_sqr); // 1 / len, inverted length
                return self.multiply(inv_len);
            }

            return self;
        }

        /// Finds the dot product of two vectors
        /// The dot product of vectors `a` and `b` `<a,b>` is given by:
        /// <a,b> = (a.x * b.x) + (a.y * b.y) + (a.z * b.z)
        pub fn dot(self: Self, other: Self) T {
            return (self.x * other.x) +
                (self.y * other.y) +
                (self.z * other.z);
        }

        /// Multiplication of a point with a 4x4 matrix
        pub fn point_mat_multiplication(self: Self, m: Mat4(T)) Self {
            const x = self.x * m.ith(0)[0] + self.y * m.ith(1)[0] + self.z * m.ith(2)[0] + m.ith(3)[0];
            const y = self.x * m.ith(0)[1] + self.y * m.ith(1)[1] + self.z * m.ith(2)[1] + m.ith(3)[1];
            const z = self.x * m.ith(0)[2] + self.y * m.ith(1)[2] + self.z * m.ith(2)[2] + m.ith(3)[2];

            // Makes this a homogenous point
            const w: T = self.x * m.ith(0)[3] + self.y * m.ith(1)[3] + self.z * m.ith(2)[3] + m.ith(3)[3];
            const vec = Self{ .x = x, .y = y, .z = z };

            // We need w = 1, so if it isn't, divide the vec by w.
            // Obviously, this will fail for w = 0.
            if (w != 1 and w != 0) {
                return vec.multiply(1 / w);
            }
            return vec;
        }

        /// Since vectors don't represent a position, their translation is meaningless
        /// This means we cna forego addition of the m.ith(3)[i] terms.
        pub fn vec_mat_multiplication(self: Self, m: Mat4(T)) Self {
            return Self{
                .x = self.x * m.ith(0)[0] + self.y * m.ith(1)[0] + self.z * m.ith(2)[0],
                .y = self.x * m.ith(0)[1] + self.y * m.ith(1)[1] + self.z * m.ith(2)[1],
                .z = self.x * m.ith(0)[2] + self.y * m.ith(1)[2] + self.z * m.ith(2)[2],
            };
        }

        /// Converts from spherical coordinates to cartesian coordinates
        pub fn spherical_to_cartesian(theta: T, phi: T) Self {
            return Self{
                .x = @cos(phi) * @sin(theta),
                .y = @sin(phi) * @sin(theta),
                .z = @cos(theta),
            };
        }

        /// Gets the theta value for spherical coordinates from cartesian coordinates
        pub fn spherical_theta(self: Self) T {
            const res = math.acos(self.z);
            if (res < -1) return -1;
            if (res > 1) return 1;
            return res;
        }

        /// Gets the phi value for spherical coordinates from cartesian coordinates
        pub fn spherical_phi(self: Self) T {
            const p = math.atan2(self.y, self.x);
            return if (p < 0) p + 2 * math.pi else p;
        }

        pub fn cos_theta(self: Self) T {
            return self.z;
        }

        pub fn sin_theta(self: Self) T {
            return sqrt(1 - pow(T, self.cos_theta(), 2));
        }

        pub fn cos_phi(self: Self) T {
            const st = self.sin_theta();
            if (st == 0) return 1;

            const temp = self.x / st;

            if (temp < -1) return -1;
            if (temp > 1) return 1;
            return temp;
        }

        pub fn sin_phi(self: Self) T {
            const st = self.sin_theta();
            if (st == 0) return 1;

            const temp = self.y / st;

            if (temp < -1) return -1;
            if (temp > 1) return 1;
            return temp;
        }

        /// Creates a coordinate system given `n`, where:
        /// `n` is a normal,
        /// `t` is the tangent,
        /// `b` is the bitangent
        pub fn coordinate_system(n: Self, t: *Self, b: *Self) void {
            t.* = if (@abs(n.x) > @abs(n.y)) {
                const inv_len = sqrt(n.x * n.x + n.z * n.z);
                return Self{ .x = n.z * inv_len, .y = 0, .z = -n.x * inv_len };
            } else {
                const inv_len = sqrt(n.y * n.y + n.z * n.z);
                return Self{ .x = 0, .y = -n.z * inv_len, .z = n.y * inv_len };
            };

            b.* = n.cross(t.*);
        }

        /// self is a point in world space which is converted into a point in raster space
        pub fn convert_to_raster(
            self: Self,
            world_to_camera: Mat4(T),
            options: PixelComputationOptions,
        ) !Self {
            const camera_space = self.point_mat_multiplication(world_to_camera);
            const screen_space_x = try camera_space.x_projection() * options.near;
            const screen_space_y = try camera_space.y_projection() * options.near;

            // NDC space is in the range [-1, 1]
            const ndc_space_x = 2 * screen_space_x / (options.right - options.left) -
                (options.right + options.left) / (options.right - options.left);
            const ndc_space_y = 2 * screen_space_y / (options.top - options.bottom) -
                (options.top + options.bottom) / (options.top - options.bottom);

            const raster_x = @as(T, @floatFromInt(options.screen_width)) * (ndc_space_x + 1) / 2;
            const raster_y = @as(T, @floatFromInt(options.screen_height)) * (1 - ndc_space_y) / 2;
            const raster = Self{
                .x = raster_x,
                .y = raster_y,
                .z = -camera_space.z,
            };

            return raster;
        }
    };
}

// Preset Vec3 types
pub const Vec3i32 = Vec3(i32);
pub const Vec3f32 = Vec3(f32);

pub fn edge_function(comptime T: type, v0: Vec3(T), v1: Vec3(T), v2: Vec3(T)) T {
    return (v2.x - v0.x) * (v1.y - v0.y) - (v2.y - v0.y) * (v1.x - v0.x);
}
