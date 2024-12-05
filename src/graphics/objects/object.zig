pub const Sphere = @import("sphere.zig").Sphere;
pub const MeshTriangle = @import("mesh_triangle.zig").MeshTriangle;

const Vec3 = @import("../../core/math/all.zig").Vec3f32;
const Vec2 = @import("../../core/math/all.zig").Vec2f32;
const ArrayList = @import("std").ArrayList;

const mat = @import("../material.zig");

pub const Object = union(enum) {
    sphere: Sphere,
    mesh_triangle: MeshTriangle,

    const Self = @This();

    pub fn get_surface_props(
        self: Self,
        P: *const Vec3,
        I: *const Vec3,
        index: usize,
        uv: *Vec2,
        normal: *Vec3,
        st: *Vec2,
    ) void {
        switch (self) {
            .sphere => |s| s.get_surface_props(P, I, index, uv, normal, st),
            .mesh_triangle => |t| t.get_surface_props(P, I, index, uv, normal, st),
        }
    }

    pub fn get_material(self: Self) mat.Material {
        return switch (self) {
            .sphere => |s| s.material,
            .mesh_triangle => |t| t.material,
        };
    }

    pub fn eval_diffuse_color(self: Self, texture: Vec2) Vec3 {
        return switch (self) {
            .mesh_triangle => |t| t.eval_diffuse_color(texture),
            else => self.get_material().diffuse_color,
        };
    }
};
