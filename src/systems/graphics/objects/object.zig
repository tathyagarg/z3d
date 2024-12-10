pub const Sphere = @import("sphere.zig").Sphere;
pub const MeshTriangle = @import("mesh_triangle.zig").MeshTriangle;

const math = @import("../../../core/math/math.zig");
const float = @import("../../../core/constants.zig").FLOAT;
const physics = @import("../../physics/physics.zig");

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = math.Vec3(float);
const Vec2f = math.Vec2(float);

const ArrayList = @import("std").ArrayList;

const mat = @import("../material.zig");

pub const Object = union(enum) {
    sphere: Sphere,
    mesh_triangle: MeshTriangle,

    const Self = @This();

    pub fn get_surface_props(
        self: Self,
        P: *const Vec3f,
        I: *const Vec3f,
        index: usize,
        uv: *Vec2f,
        normal: *Vec3f,
        st: *Vec2f,
    ) void {
        switch (self) {
            .sphere => |s| s.get_surface_props(P, I, index, uv, normal, st),
            .mesh_triangle => |t| t.get_surface_props(P, I, index, uv, normal, st),
        }
    }

    pub fn get_material(self: Self) *mat.Material {
        return switch (self) {
            .sphere => |s| s.material,
            .mesh_triangle => |t| t.material,
        };
    }

    pub fn eval_diffuse_color(self: Self, texture: Vec2f) Vec3f {
        return switch (self) {
            .mesh_triangle => |t| t.eval_diffuse_color(texture),
            else => self.get_material().diffuse_color,
        };
    }

    pub fn get_physics_engine(self: Self) ?*physics.PhysicsEngine {
        return switch (self) {
            .sphere => |s| s.physics,
            .mesh_triangle => |t| t.physics,
        };
    }

    pub fn add_physics(self: *Self, phy: *physics.PhysicsEngine) void {
        switch (self.*) {
            .sphere => self.sphere.physics = phy,
            .mesh_triangle => self.mesh_triangle.physics = phy,
        }
    }
};
