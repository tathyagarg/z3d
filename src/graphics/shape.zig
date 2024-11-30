const Disk = @import("shapes/disk.zig").Disk;
const Plane = @import("shapes/plane.zig").Plane;
const Triangle = @import("shapes/triangle.zig").Triangle;

pub const ShapeTag = enum {
    disk,
    plane,
    triangle,
};

pub const Shape = union(ShapeTag) {
    disk: Disk,
    plane: Plane,
    triangle: Triangle,
};
