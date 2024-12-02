const Vec3 = @import("../../core/math/primitives.zig").Vec3;
const Ray = @import("../ray.zig").Ray;

pub const Plane = struct {
    origin: Vec3,
    normal: Vec3,

    /// This function is a translation of the C++ code:
    /// bool intersectPlane(const Vec3f &n, const Vec3f &p0, const Vec3f &l0, const Vec3f &l, float &t)
    /// {
    ///     // Assuming vectors are all normalized
    ///     float denom = dotProduct(n, l);
    ///     if (denom > 1e-6) {
    ///         Vec3f p0l0 = p0 - l0;
    ///         t = dotProduct(p0l0, n) / denom;
    ///         return (t >= 0);
    ///     }
    ///
    ///     return false;
    /// }
    ///
    /// Learn more:
    /// https://www.scratchapixel.com/lessons/3d-basic-rendering/minimal-ray-tracer-rendering-simple-shapes/ray-plane-and-ray-disk-intersection.html
    pub fn ray_intersects(self: Plane, ray: Ray, t: *f32) bool {
        const denom: f32 = self.normal.dot_product(ray.direction);
        if (denom >= 1e-6) {
            const p0l0: Vec3 = self.origin.subtract(ray.origin);
            t.* = p0l0.dot_product(self.normal) / denom;

            return (t.* >= 0);
        }

        return false;
    }
};
