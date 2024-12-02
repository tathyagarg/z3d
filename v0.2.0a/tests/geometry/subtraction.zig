const utils = @import("utils.zig");

const Vec3 = utils.Vec3;
const vertices = utils.vertices;

const std = @import("std");
const expect = std.testing.expect;

test "subtraction" {
    const edge_v1 = vertices[1].subtract(vertices[0]);
    const edge_v2 = vertices[2].subtract(vertices[0]);

    try expect(edge_v1 == Vec3.init(0, 0, 1));
    try expect(edge_v2 == Vec3.init(1, 0, 0));
}
