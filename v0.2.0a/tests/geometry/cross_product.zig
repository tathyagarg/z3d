const utils = @import("utils.zig");

const Vec3 = utils.Vec3;
const vertices = utils.vertices;

const std = @import("std");
const expect = std.testing.expect;

test "cross product" {
    // Find the normal of the triangle formed by vertices
    const v1 = vertices[1].subtract(vertices[0]);
    const v2 = vertices[2].subtract(vertices[0]);

    const normal = v1.cross(v2);

    try expect(normal == Vec3.init(0, 1, 0));
}
