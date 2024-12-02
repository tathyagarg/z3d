const constants = @import("z3d").constants;
const utils = @import("utils.zig");

const corners = utils.corners;
const Vec3 = utils.Vec3;

const std = @import("std");
const expect = std.testing.expect;
const expectErr = std.testing.expectError;

test "cube perspective divide" {
    for (0..corners.len) |i| {
        const x_projection: f32 = try corners[i].x_projection();
        const y_projection: f32 = try corners[i].y_projection();

        try expect(x_projection == corners[i].x / -corners[i].z);
        try expect(y_projection == corners[i].y / -corners[i].z);
    }
}

test "erroneous perspective divide" {
    const corner = Vec3.init(1, 1, 0);

    try expectErr(error.ZisZero, corner.x_projection());
    try expectErr(error.ZisZero, corner.y_projection());
}
