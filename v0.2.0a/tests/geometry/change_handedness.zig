const utils = @import("utils.zig");

const Vec3 = utils.Vec3;
const vertices = utils.vertices;

const std = @import("std");
const expect = std.testing.expect;

test "change handedness" {
    const changed_vertices = [3]Vec3{
        vertices[0].change_handedness(),
        vertices[1].change_handedness(),
        vertices[2].change_handedness(),
    };

    const v1 = changed_vertices[1].subtract(changed_vertices[0]);
    const v2 = changed_vertices[2].subtract(changed_vertices[0]);

    const normal = v1.cross(v2);

    try expect(normal == Vec3.init(0, -1, 0));
}
