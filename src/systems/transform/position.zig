const math = @import("../../core/math/math.zig");
const float = @import("../../core/constants.zig").FLOAT;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);

pub const Bounds = struct {
    minimum: Vec3f,
    maximum: Vec3f,
};

pub const SinglePointHandler = struct {
    point: *Vec3f,
    is_static: bool = false,
};

pub const MultiPointHandler = struct {
    points: [*]Vec3f,
    point_count: usize,
    is_static: bool = false,

    const Self = @This();

    pub fn bounding_box(self: Self) Bounds {
        var minimum = Vec3f.infinity();
        var maximum = Vec3f.infinity().negate();

        for (self.points) |p| {
            minimum.x = @min(p.x, minimum.x);
            minimum.y = @min(p.y, minimum.y);
            minimum.z = @min(p.z, minimum.z);

            maximum.x = @max(p.x, maximum.x);
            maximum.y = @max(p.y, maximum.y);
            maximum.z = @max(p.z, maximum.z);
        }

        return Bounds{ .minimum = minimum, .maximum = maximum };
    }
};

pub const PositionHandler = union(enum) {
    single: SinglePointHandler,
    multi: MultiPointHandler,

    const Self = @This();

    pub fn translate(self: Self, dxyz: Vec3f) !void {
        switch (self) {
            .single => |s| {
                if (s.is_static) {
                    return error.CannotTranslateStaticBody;
                }
                s.point.* = s.point.add(dxyz);
            },
            .multi => |m| {
                if (m.is_static) {
                    return error.CannotTranslateStaticBody;
                }
                for (0..m.point_count) |i| {
                    m.points[i] = m.points[i].add(dxyz);
                }
            },
        }
    }
};
