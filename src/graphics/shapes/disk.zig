const Vec3 = @import("../../core/math/primitives.zig").Vec3;
const Ray = @import("../ray.zig").Ray;
const Plane = @import("./plane.zig").Plane;

pub const Disk = struct {
    origin: Vec3,
    normal: Vec3,
    radius: f32,

    pub fn ray_intersects(self: Disk, ray: Ray) bool {
        const plane = Plane{ .origin = self.origin, .normal = self.normal };
        const result = plane.ray_intersects(ray);
        const intersects = result[0];
        if (intersects) {
            const intersection_point = ray.at(result[1]);
            const distance = intersection_point.subtract(self.origin);
            const sqred = distance.dot_product(distance);

            return sqred <= (self.radius * self.radius);
        }

        return false;
    }
};
