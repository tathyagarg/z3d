const math = @import("../../../core/math/math.zig");
const float = @import("../../../core/constants.zig").FLOAT;
const physics = @import("../../physics/physics.zig");
const position = @import("../../transform/transform.zig").position;

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = Vec3(float);
const Vec2f = Vec2(float);

const Ray = @import("../ray.zig").Ray;
const Material = @import("../material.zig").Material;
const ArrayList = @import("std").ArrayList;

pub const MeshTriangle = struct {
    position: position.PositionHandler,
    vertex_indices: []const usize,
    num_triangles: u32,
    textures: []const Vec2f,

    material: *Material,
    physics: ?*physics.PhysicsEngine = null,

    const Self = @This();

    pub fn init(
        vertices: *[*]Vec3f,
        vertex_count: usize,
        vertex_indices: []const usize,
        num_triangles: u32,
        textures: []const Vec2f,
        material: *Material,
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

    pub fn intersects(self: Self, ray: Ray, tn: *float, index: *usize, uv: *Vec2f) bool {
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

        _ = .{ self, P, I };
    }
};
