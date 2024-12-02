const Vec3 = @import("../../core/math/primitives.zig").Vec3;
const Material = @import("../material.zig").Material;
const Ray = @import("../ray.zig").Ray;

const std = @import("std");
const ziglog = @import("ziglog");

pub const Triangle = struct {
    points: struct { a: Vec3, b: Vec3, c: Vec3 },
    material: Material,

    pub fn normal(self: Triangle) !Vec3 {
        // const logger = try ziglog.Logger.get(.{ .name = "console" });

        const AB = self.points.b.subtract(self.points.a); // Edge 1
        const AC = self.points.c.subtract(self.points.a); // Edge 2

        const unnormalized_normal_vec = AB.cross_product(AC);
        const normal_vec = unnormalized_normal_vec.normalize();

        // try logger.debug(try std.fmt.allocPrint(std.heap.page_allocator, "AB: {d} {d} {d}, AC: {d} {d} {d}, Un: {d} {d} {d}, N: {d} {d} {d}", .{ AB.x, AB.y, AB.z, AC.x, AC.y, AC.z, unnormalized_normal_vec.x, unnormalized_normal_vec.y, unnormalized_normal_vec.z, normal_vec.x, normal_vec.y, normal_vec.z }));

        return normal_vec;
    }

    /// Learn more:
    /// https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/ray-triangle-intersection-geometric-solution.html
    pub fn ray_intersects(self: Triangle, ray: Ray) !bool {
        // const logger = try ziglog.Logger.get(.{ .name = "console" });
        // try logger.debug(try std.fmt.allocPrint(
        //     std.heap.page_allocator,
        //     "Direction: {d} {d} {d}, Origin: {d} {d} {d}",
        //     .{ ray.direction.x, ray.direction.y, ray.direction.z, ray.origin.x, ray.origin.y, ray.origin.z },
        // ));

        const ab: Vec3 = self.points.b.subtract(self.points.a);
        const norm: Vec3 = try self.normal();

        const normal_dot_ray_dir: f32 = norm.dot_product(ray.direction);
        if (@abs(normal_dot_ray_dir) < 1e-6) {
            return false;
        }

        const d: f32 = -norm.dot_product(self.points.a);
        const t = -(norm.dot_product(ray.origin) + d) / normal_dot_ray_dir;

        // try logger.debug(try std.fmt.allocPrint(
        //     std.heap.page_allocator,
        //     "Normal Dot Ray Dir: {d}, Norm: {d} {d} {d} T: {d}",
        //     .{ normal_dot_ray_dir, norm.x, norm.y, norm.z, t },
        // ));
        if (t < 0) return false;

        var norm2: Vec3 = undefined;

        const intersection = ray.at(t);
        const ap = intersection.subtract(self.points.a);
        norm2 = ab.cross_product(ap);
        if (norm.dot_product(norm2) < 0) {
            // try logger.err("Fucked on 1");
            return false;
        }

        const cb = self.points.c.subtract(self.points.b);
        const bp = intersection.subtract(self.points.b);
        norm2 = cb.cross_product(bp);
        if (norm.dot_product(norm2) < 0) {
            // try logger.err("Fucked on 2");
            return false;
        }

        const ca = self.points.a.subtract(self.points.c);
        const cp = intersection.subtract(self.points.c);
        norm2 = ca.cross_product(cp);
        if (norm.dot_product(norm2) < 0) {
            // try logger.err("Fucked on 3");
            return false;
        }

        return true;
    }
};
