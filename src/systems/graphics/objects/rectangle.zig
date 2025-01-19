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

pub const Rectangle = struct {
    vertices: [4]Vec3f,

    position: position.PositionHandler,
    material: *const Material,
    physics: ?*physics.PhysicsEngine = null,

    textures: [4]Vec2f = [4]Vec2f{
        Vec2f.init(0, 0),
        Vec2f.init(1, 0),
        Vec2f.init(1, 1),
        Vec2f.init(0, 1),
    },
    is_double_sided: bool = false,

    normal: Vec3f = undefined,

    pub fn init(
        vertices: [4]Vec3f,
        material: *const Material,
        physics_engine: ?*physics.PhysicsEngine,
        inverted: bool,
    ) Rectangle {
        var rect = Rectangle{
            .vertices = vertices,
            .position = position.PositionHandler{
                .multi = position.MultiPointHandler{
                    .points = @ptrCast(&vertices),
                    .point_count = 4,
                },
            },
            .material = material,
            .physics = physics_engine,
        };
        rect.compute_normal(inverted);

        return rect;
    }

    pub fn compute_normal(self: *Rectangle, inverted: bool) void {
        self.normal = self.vertices[1]
            .subtract(self.vertices[0])
            .cross(self.vertices[2].subtract(self.vertices[0]))
            .normalize()
            .multiply(if (inverted) -1 else 1);
    }

    pub fn get_surface_props(
        self: Rectangle,
        uv: *Vec2f,
        normal: *Vec3f,
        st: *Vec2f,
    ) void {
        normal.* = self.normal;

        st.* = self.textures[0].multiply((1 - uv.x) * (1 - uv.y))
            .add(self.textures[1].multiply(uv.x * (1 - uv.y)))
            .add(self.textures[2].multiply(uv.x * uv.y))
            .add(self.textures[3].multiply((1 - uv.x) * uv.y));
    }

    pub fn eval_diffuse_color(self: Rectangle, texture: Vec2f) Vec3f {
        return switch (self.material.texture) {
            .SOLID_COLOR => |color| color.rgb_to_vec(),
            .TEXTURE_FILE => |image| {
                const rgb = image.sample(texture);
                const vec = rgb.rgb_to_vec();
                return vec;
            },
        };
    }

    pub fn intersects(self: Rectangle, ray: Ray, tn: *float, uv_k: *Vec2f) bool {
        // const denom = self.normal.dot(ray.direction);
        // if (@abs(denom) < 1e-6) return false;

        // const t = self.normal.dot(self.vertices[0].subtract(ray.origin)) / denom;
        // if (@abs(t) < 1e-6) return false;

        // const intersection_point = ray.at(t);
        // tn.* = t;

        // return self.is_inside(intersection_point);
        const edge1 = self.vertices[1].subtract(self.vertices[0]);
        const edge2 = self.vertices[3].subtract(self.vertices[0]);

        const denom = ray.direction.dot(self.normal);
        if (@abs(denom) < 1e-6) return false;

        const t = self.vertices[0]
            .subtract(ray.origin)
            .dot(self.normal) / denom;
        if (t < 0) return false;

        const intersection_point = ray.at(t);

        const local_u = intersection_point
            .subtract(self.vertices[0])
            .dot(edge1) / edge1.dot(edge1);
        const local_v = intersection_point
            .subtract(self.vertices[0])
            .dot(edge2) / edge2.dot(edge2);

        if (local_u < 0 or local_u > 1 or local_v < 0 or local_v > 1) return false;

        // std.debug.print("yes\n", .{});
        tn.* = t;
        uv_k.x = local_u;
        uv_k.y = local_v;
        return true;
    }

    /// I'm so sorry.
    pub fn is_inside(self: Rectangle, point: Vec3f) bool {
        const max_x = @max(self.vertices[0].x, self.vertices[2].x);
        const max_y = @max(self.vertices[0].y, self.vertices[2].y);
        const max_z = @max(self.vertices[0].z, self.vertices[2].z);

        const min_x = @min(self.vertices[0].x, self.vertices[2].x);
        const min_y = @min(self.vertices[0].y, self.vertices[2].y);
        const min_z = @min(self.vertices[0].z, self.vertices[2].z);

        return point.x >= min_x and
            point.x <= max_x and
            point.y >= min_y and
            point.y <= max_y and
            point.z >= min_z and
            point.z <= max_z;
    }

    pub fn rotate_clockwise(self: *Rectangle, turns: u2) *Rectangle {
        for (0..turns) |_| {
            self.textures = [4]Vec2f{
                self.textures[1],
                self.textures[2],
                self.textures[3],
                self.textures[0],
            };
        }
        return self;
    }

    pub fn rotate_counterclockwise(self: *Rectangle, turns: u2) *Rectangle {
        for (0..turns) |_| {
            self.textures = [4]Vec2f{
                self.textures[3],
                self.textures[0],
                self.textures[1],
                self.textures[2],
            };
        }
        return self;
    }
};

pub fn Cuboid(
    vertices: [8]Vec3f,
    materials: [6]*const Material,
    physics_engine: ?*physics.PhysicsEngine,
    inverted: bool,
) [6]Rectangle {
    return [6]Rectangle{
        Rectangle.init(
            [4]Vec3f{
                vertices[0],
                vertices[1],
                vertices[2],
                vertices[3],
            },
            materials[0],
            physics_engine,
            !inverted,
        ),
        Rectangle.init(
            [4]Vec3f{
                vertices[4],
                vertices[5],
                vertices[6],
                vertices[7],
            },
            materials[1],
            physics_engine,
            inverted,
        ),
        Rectangle.init(
            [4]Vec3f{
                vertices[0],
                vertices[1],
                vertices[5],
                vertices[4],
            },
            materials[2],
            physics_engine,
            inverted,
        ),
        Rectangle.init(
            [4]Vec3f{
                vertices[1],
                vertices[2],
                vertices[6],
                vertices[5],
            },
            materials[3],
            physics_engine,
            inverted,
        ),
        Rectangle.init(
            [4]Vec3f{
                vertices[2],
                vertices[3],
                vertices[7],
                vertices[6],
            },
            materials[4],
            physics_engine,
            inverted,
        ),
        Rectangle.init(
            [4]Vec3f{
                vertices[3],
                vertices[0],
                vertices[4],
                vertices[7],
            },
            materials[5],
            physics_engine,
            inverted,
        ),
    };
}
