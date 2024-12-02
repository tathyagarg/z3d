const Vec3 = @import("../../core/math/primitives.zig").Vec3;
const Material = @import("../material.zig").Material;
const Ray = @import("../ray.zig").Ray;
const Plane = @import("./plane.zig").Plane;

pub const Disk = struct {
    origin: Vec3,
    normal: Vec3,
    radius: f32,

    material: Material,

    pub fn ray_intersects(self: Disk, ray: Ray) bool {
        const plane = Plane{ .origin = self.origin, .normal = self.normal };
        var t: f32 = 0.0;

        const intersects = plane.ray_intersects(ray, &t);
        if (intersects) {
            const intersection_point = ray.at(t);
            const distance = intersection_point.subtract(self.origin);
            const sqred = distance.dot_product(distance);

            return sqred <= (self.radius * self.radius);
        }

        return false;
    }
};
