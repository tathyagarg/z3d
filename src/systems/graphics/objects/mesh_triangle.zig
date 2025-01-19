const std = @import("std");

const math = @import("../../../core/math/math.zig");
const float = @import("../../../core/constants.zig").FLOAT;
const physics = @import("../../physics/physics.zig");
const position = @import("../../transform.zig");

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = Vec3(float);
const Vec2f = Vec2(float);

const Bounds = math.Bounds(Vec3f);

const Ray = @import("../ray.zig").Ray;
const Material = @import("../material.zig").Material;
const ArrayList = @import("std").ArrayList;

const RGB = @import("../graphics.zig").RGB;

pub const MeshTriangle = struct {
    id: ?usize = null,

    position: position.PositionHandler,
    vertex_indices: []const usize,
    num_triangles: u32,
    textures: []const Vec2f,

    material: *const Material,
    physics: ?*physics.PhysicsEngine = null,

    const Self = @This();

    pub fn init(
        vertices: *const []Vec3f,
        vertex_count: usize,
        vertex_indices: []const usize,
        num_triangles: u32,
        textures: []const Vec2f,
        material: *const Material,
        physics_engine: ?*physics.PhysicsEngine,
    ) Self {
        return Self{
            .position = position.PositionHandler{
                .multi = position.MultiPointHandler{
                    .points = vertices.*,
                    .point_count = vertex_count,
                },
            },
            .vertex_indices = vertex_indices,
            .num_triangles = num_triangles,
            .textures = textures,
            .material = material,
            .physics = physics_engine,
        };
    }

    /// Blatantly copied from ChatGPT
    pub fn intersect_ray_aabb(self: Self, ray: Ray) bool {
        const aabb = self.position.multi.bounding_box();
        // Compute the t values for the x, y, and z axes
        var tmin = (aabb.minimum.x - ray.origin.x) / ray.direction.x;
        var tmax = (aabb.maximum.x - ray.origin.x) / ray.direction.x;

        var tmin_y = (aabb.minimum.y - ray.origin.y) / ray.direction.y;
        var tmax_y = (aabb.maximum.y - ray.origin.y) / ray.direction.y;

        // Check if ray does not intersect AABB in the x-axis
        if (tmin > tmax) {
            const tmp = tmin;
            tmin = tmax;
            tmax = tmp;
        }

        // Check intersection for y-axis
        if (tmin_y > tmax_y) {
            const tmp = tmin_y;
            tmin_y = tmax_y;
            tmax_y = tmp;
        }

        // If no intersection on either axis, return false
        if (tmin > tmax_y or tmin_y > tmax) {
            return false;
        }

        // Adjust the tmin and tmax to consider both x and y axes
        if (tmin_y > tmin) {
            tmin = tmin_y;
        }
        if (tmax_y < tmax) {
            tmax = tmax_y;
        }

        // Now check the z-axis
        var tmin_z = (aabb.minimum.z - ray.origin.z) / ray.direction.z;
        var tmax_z = (aabb.maximum.z - ray.origin.z) / ray.direction.z;

        if (tmin_z > tmax_z) {
            const tmp = tmin_z;
            tmin_z = tmax_z;
            tmax_z = tmp;
        }

        // Final check to ensure intersection on all axes
        if (tmin > tmax_z or tmin_z > tmax) {
            return false;
        }

        return true;
    }

    pub fn intersects(self: Self, ray: Ray, tn: *float, index: *usize, uv: *Vec2f) bool {
        // Optimization ideas:
        // - Use a bounding box to check if the ray intersects the mesh before checking each triangle.
        // - Use a BVH to speed up the intersection tests.
        // - Use a more efficient intersection test for triangles.
        // - Use SIMD to check multiple triangles at once.

        // Bounding box check for optimizations
        if (!self.intersect_ray_aabb(ray)) {
            return false;
        }

        var intersect: bool = false;
        for (0..self.num_triangles) |k| {
            const v0: Vec3f = self.position.multi.points[self.vertex_indices[k * 3 + 0]];
            const v1: Vec3f = self.position.multi.points[self.vertex_indices[k * 3 + 1]];
            const v2: Vec3f = self.position.multi.points[self.vertex_indices[k * 3 + 2]];

            var t: float = undefined;
            var u: float = undefined;
            var v: float = undefined;

            if (ray.triangle_intersect(v0, v1, v2, &t, &u, &v) and t < tn.*) {
                tn.* = t;
                uv.x = u;
                uv.y = v;
                index.* = k;

                intersect = true;
            }
        }

        return intersect;
    }

    pub fn eval_diffuse_color(self: Self, texture: Vec2f) Vec3f {
        // The diffuse color is a pattern, independent of `self` and it's properties. Thus, we're free to discard it here.
        return switch (self.material.texture) {
            .SOLID_COLOR => |color| color.rgb_to_vec().mix(
                (RGB{ .r = 0, .g = 0, .b = 0 }).rgb_to_vec(),
                texture.x - texture.y,
            ),
            .TEXTURE_FILE => |image| image.sample(texture).rgb_to_vec(),
        };
    }

    pub fn get_surface_props(
        self: Self,
        index: usize,
        uv: *Vec2f,
        normal: *Vec3f,
        st: *Vec2f,
    ) void {
        const v0: Vec3f = self.position.multi.points[self.vertex_indices[index * 3 + 0]];
        const v1: Vec3f = self.position.multi.points[self.vertex_indices[index * 3 + 1]];
        const v2: Vec3f = self.position.multi.points[self.vertex_indices[index * 3 + 2]];

        const e0: Vec3f = v1.subtract(v0).normalize();
        const e1: Vec3f = v2.subtract(v1).normalize();

        normal.* = e0.cross(e1).normalize();

        const st0: Vec2f = self.textures[self.vertex_indices[index * 3 + 0]];
        const st1: Vec2f = self.textures[self.vertex_indices[index * 3 + 1]];
        const st2: Vec2f = self.textures[self.vertex_indices[index * 3 + 2]];

        st.* = st0.multiply(1 - uv.x - uv.y)
            .add(st1.multiply(uv.x))
            .add(st2.multiply(uv.y));
    }
};

pub fn Cuboid(
    vertices: *const []Vec3f,
    material: *const Material,
    physics_engine: ?*physics.PhysicsEngine,
) MeshTriangle {
    return MeshTriangle.init(
        vertices,
        8,
        &.{
            0, 1, 2,
            2, 3, 0,
            4, 5, 6,
            6, 7, 4,
            0, 4, 5,
            5, 1, 0,
            1, 5, 6,
            6, 2, 1,
            2, 6, 7,
            7, 3, 2,
            3, 7, 4,
            4, 0, 3,
        },
        12,
        &.{
            Vec2f{ .x = 1, .y = 0 },
            Vec2f{ .x = 0, .y = 1 },
            Vec2f{ .x = 1, .y = 0 },
            Vec2f{ .x = 0, .y = 1 },
            Vec2f{ .x = 1, .y = 0 },
            Vec2f{ .x = 0, .y = 1 },
            Vec2f{ .x = 0, .y = 1 },
            Vec2f{ .x = 0, .y = 1 },
        },
        material,
        physics_engine,
    );
}
