const Vec3 = @import("../../core/math/all.zig").Vec3f32;
const Vec2 = @import("../../core/math/all.zig").Vec2f32;
const Ray = @import("../ray.zig").Ray;
const ArrayList = @import("std").ArrayList;
const Material = @import("../material.zig").Material;

pub const MeshTriangle = struct {
    vertices: []const Vec3,
    vertex_indices: []const usize,
    num_triangles: u32,
    textures: []const Vec2,
    material: Material,

    const Self = @This();

    pub fn intersects(self: Self, ray: Ray, tn: *f32, index: *usize, uv: *Vec2) bool {
        var intersect = false;
        for (0..self.num_triangles) |k| {
            const v0 = self.vertices[self.vertex_indices[k * 3 + 0]];
            const v1 = self.vertices[self.vertex_indices[k * 3 + 1]];
            const v2 = self.vertices[self.vertex_indices[k * 3 + 2]];

            var t: f32 = undefined;
            var u: f32 = undefined;
            var v: f32 = undefined;

            if (ray.triangle_intersect(v0, v1, v2, &t, &u, &v) and t < tn.*) {
                tn.* = t;
                uv.*.x = u;
                uv.*.y = v;
                index.* = k;

                intersect = true;
            }
        }
        return intersect;
    }

    pub fn eval_diffuse_color(self: Self, texture: Vec2) Vec3 {
        _ = .{self};
        const scale = 5;
        const pattern = @as(
            f32,
            @floatFromInt(
                @as(u8, @intFromBool(@mod(texture.x * scale, 1) > 0.5)) ^
                    @as(u8, @intFromBool(@mod(texture.y * scale, 1) > 0.5)),
            ),
        );

        return (Vec3{ .x = 0.82, .y = 0.235, .z = 0.03 }).mix(
            Vec3{ .x = 0.937, .y = 0.937, .z = 0.235 },
            pattern,
        );
    }

    pub fn get_surface_props(
        self: Self,
        P: *const Vec3,
        I: *const Vec3,
        index: usize,
        uv: *Vec2,
        normal: *Vec3,
        st: *Vec2,
    ) void {
        const v0 = self.vertices[self.vertex_indices[index * 3 + 0]];
        const v1 = self.vertices[self.vertex_indices[index * 3 + 1]];
        const v2 = self.vertices[self.vertex_indices[index * 3 + 2]];

        const e0 = v1.subtract(v0).normalize();
        const e1 = v2.subtract(v1).normalize();

        normal.* = e0.cross(e1).normalize();

        const st0 = self.textures[self.vertex_indices[index * 3 + 0]];
        const st1 = self.textures[self.vertex_indices[index * 3 + 1]];
        const st2 = self.textures[self.vertex_indices[index * 3 + 2]];
        st.* = st0.multiply(1 - uv.x - uv.y).add(st1.multiply(uv.x)).add(st2.multiply(uv.y));

        _ = .{ self, P, I };
    }
};
