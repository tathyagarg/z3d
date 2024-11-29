const Vec3 = @import("primitives.zig").Vec3;
const Vec4 = @import("primitives.zig").Vec4;
const math = @import("std").math;

const errs = @import("../errors.zig").Errors;

pub const Quaternion = struct {
    data: Vec4,

    pub fn identity() Quaternion {
        return Quaternion{
            .data = Vec4{ .w = 1, .x = 0, .y = 0, .z = 0 },
        };
    }

    pub fn from_axis(axis: Vec3, angle: i16) Quaternion {
        return Quaternion{ .data = Vec4{
            .x = math.sin(angle / 2) * axis.x,
            .y = math.sin(angle / 2) * axis.y,
            .z = math.sin(angle / 2) * axis.z,
            .w = math.cos(angle / 2),
        } };
    }

    pub fn multiply(self: Quaternion, other: Quaternion) Quaternion {
        return Quaternion{ .data = Vec4{
            .w = (self.w * other.w - self.x * other.x - self.y * other.y - self.z * other.z),
            .x = (self.w * other.x + self.x * other.w + self.y * other.z - self.z * other.y),
            .y = (self.w * other.y - self.x * other.z + self.y * other.w + self.z * other.x),
            .z = (self.w * other.z + self.x * other.y - self.y * other.x + self.z * other.w),
        } };
    }

    pub fn conjugate(self: Quaternion) Quaternion {
        return Quaternion{ .data = Vec4{
            .w = self.w,
            .x = -self.x,
            .y = -self.y,
            .z = -self.z,
        } };
    }

    pub fn norm(self: Quaternion) f32 {
        return math.sqrt(self.w * self.w +
            self.x * self.x +
            self.y * self.y +
            self.z * self.z);
    }

    pub fn inverse(self: Quaternion) Quaternion {
        const conj = self.conjugate();
        const norm_sqr = math.pow(self.norm(), 2);

        const data = conj.data.divide(norm_sqr);
        return Quaternion{ .data = data };
    }

    pub fn normalize(self: Quaternion) Quaternion {
        const data = self.data.divide(self.norm());
        return Quaternion{ .data = data };
    }

    pub fn slerp(self: Quaternion, other: Quaternion, t: f32) Quaternion {
        if (t > 1 or t < 0) {
            return errs.InvalidParameter;
        }

        const theta = math.acos(self.data.dot_product(other.data));

        const v1 = self.data.multiply(math.sin((1 - t) * theta) / math.sin(theta));
        const v2 = other.data.multiply(math.sin(t * theta) / math.sin(theta));

        const vres = v1.add(v2);
        return Quaternion{ .data = vres };
    }

    pub fn lerp(self: Quaternion, other: Quaternion, t: f32) Quaternion {
        if (t > 1 or t < 0) {
            return errs.InvalidParameter;
        }

        const v1 = self.data.multiply(1 - t);
        const v2 = other.data.multiply(t);

        const vres = v1.add(v2);

        return Quaternion{ .data = vres };
    }
};
