const math = @import("../../core/math/all.zig");
const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = Vec3(float);
const Vec2f = Vec2(float);

const Ray = @import("../ray.zig").Ray;
const Material = @import("../material.zig").Material;
const ArrayList = @import("std").ArrayList;

pub const MeshTriangle = struct {
    vertices: []const Vec3f,
    vertex_indices: []const usize,
    num_triangles: u32,
    textures: []const Vec2f,
    material: Material,

    const Self = @This();

    pub fn intersects(self: Self, ray: Ray, tn: *float, index: *usize, uv: *Vec2f) bool {
        var intersect: bool = false;
        for (0..self.num_triangles) |k| {
            const v0: Vec3f = self.vertices[self.vertex_indices[k * 3 + 0]];
            const v1: Vec3f = self.vertices[self.vertex_indices[k * 3 + 1]];
            const v2: Vec3f = self.vertices[self.vertex_indices[k * 3 + 2]];

            var t: float = undefined;
            var u: float = undefined;
            var v: float = undefined;

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

    pub fn eval_diffuse_color(self: Self, texture: Vec2f) Vec3f {
        // The diffuse color is a pattern, independent of `self` and it's properties. Thus, we're free to discard it here.
        _ = .{self};
        const scale: usize = 20;
        const pattern: float = @as(
            float,
            @floatFromInt(
                @as(u8, @intFromBool(@mod(texture.x * scale, 1) > 0.5)) ^
                    @as(u8, @intFromBool(@mod(texture.y * scale, 1) > 0.5)),
            ),
        );

        return (Vec3f{ .x = 0.82, .y = 0.235, .z = 0.03 }).mix(
            Vec3f{ .x = 0.937, .y = 0.937, .z = 0.235 },
            pattern,
        );
    }

    pub fn get_surface_props(
        self: Self,
        P: *const Vec3f,
        I: *const Vec3f,
        index: usize,
        uv: *Vec2f,
        normal: *Vec3f,
        st: *Vec2f,
    ) void {
        const v0: Vec3f = self.vertices[self.vertex_indices[index * 3 + 0]];
        const v1: Vec3f = self.vertices[self.vertex_indices[index * 3 + 1]];
        const v2: Vec3f = self.vertices[self.vertex_indices[index * 3 + 2]];

        const e0: Vec3f = v1.subtract(v0).normalize();
        const e1: Vec3f = v2.subtract(v1).normalize();

        normal.* = e0.cross(e1).normalize();

        const st0: Vec2f = self.textures[self.vertex_indices[index * 3 + 0]];
        const st1: Vec2f = self.textures[self.vertex_indices[index * 3 + 1]];
        const st2: Vec2f = self.textures[self.vertex_indices[index * 3 + 2]];
        st.* = st0.multiply(1 - uv.x - uv.y)
            .add(st1.multiply(uv.x))
            .add(st2.multiply(uv.y));

        _ = .{ self, P, I };
    }
};
