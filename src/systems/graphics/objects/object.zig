const std = @import("std");
pub const Sphere = @import("sphere.zig").Sphere;
pub const MeshTriangle = @import("mesh_triangle.zig").MeshTriangle;
pub const Rectangle = @import("rectangle.zig").Rectangle;
pub const MeshCuboid = @import("mesh_triangle.zig").Cuboid;
pub const Cuboid = @import("rectangle.zig").Cuboid;
pub const CuboidMaterial = @import("rectangle.zig").CuboidMaterial;
pub const PerFace = @import("rectangle.zig").PerFace;

const math = @import("../../../core/math/math.zig");
const float = @import("../../../core/constants.zig").FLOAT;
const physics = @import("../../physics/physics.zig");
const PositionHandler = @import("../../transform.zig").PositionHandler;

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = math.Vec3(float);
const Vec2f = math.Vec2(float);

const ArrayList = @import("std").ArrayList;

const mat = @import("../material.zig");

pub var id_counter: usize = 0;

pub fn assigned(obj: *Object) void {
    obj.assign_id();
    id_counter += 1;
}

pub const Object = union(enum) {
    sphere: Sphere,
    mesh_triangle: MeshTriangle,
    rectangle: Rectangle,

    const Self = @This();

    pub fn get_surface_props(
        self: Self,
        P: *const Vec3f,
        index: usize,
        uv: *Vec2f,
        normal: *Vec3f,
        st: *Vec2f,
    ) void {
        switch (self) {
            .sphere => |s| s.get_surface_props(P, normal),
            .mesh_triangle => |t| t.get_surface_props(index, uv, normal, st),
            .rectangle => |r| r.get_surface_props(uv, normal, st),
        }
    }

    pub fn assign_id(self: *Self) void {
        switch (self.*) {
            .sphere => |*s| s.id = id_counter,
            .mesh_triangle => |*m| m.id = id_counter,
            .rectangle => |*r| r.id = id_counter,
        }

        id_counter += 1;
    }

    pub fn get_id(self: Self) usize {
        // std.debug.print("Iam: {any}", .{self.});
        return switch (self) {
            .sphere => |s| s.id.?,
            .mesh_triangle => |m| m.id.?,
            .rectangle => |r| {
                return r.id.?;
            },
        };
    }

    pub fn get_material(self: Self) *const mat.Material {
        return switch (self) {
            .sphere => |s| s.material,
            .mesh_triangle => |t| t.material,
            .rectangle => |r| r.material,
        };
    }

    pub fn eval_diffuse_color(self: Self, texture: Vec2f) Vec3f {
        return switch (self) {
            .mesh_triangle => |t| t.eval_diffuse_color(texture),
            .rectangle => |r| r.eval_diffuse_color(texture),
            else => switch (self.get_material().texture) {
                .SOLID_COLOR => |color| color.rgb_to_vec(),
                .TEXTURE_FILE => unreachable,
            },
        };
    }

    pub fn get_position_handler(self: Self) PositionHandler {
        return switch (self) {
            .sphere => |sphere| sphere.position,
            .mesh_triangle => |mesh| mesh.position,
            .rectangle => |rect| rect.position,
        };
    }

    pub fn get_physics_engine(self: Self) ?*physics.PhysicsEngine {
        return switch (self) {
            .sphere => |s| s.physics,
            .mesh_triangle => |t| t.physics,
            .rectangle => |r| r.physics,
        };
    }

    pub fn add_physics(self: *Self, phy: *physics.PhysicsEngine) void {
        switch (self.*) {
            .sphere => self.sphere.physics = phy,
            .mesh_triangle => self.mesh_triangle.physics = phy,
            .rectangle => self.rectangle.physics = phy,
        }
    }

    pub fn intersects(self: Self, other: Object) struct { bool, Vec3f } {
        return switch (self) {
            .sphere => |s| s.object_intersects(other),
            else => unreachable, // TODO:
        };
    }
};
