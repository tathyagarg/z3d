const constants = @import("z3d").constants;
const utils = @import("utils.zig");

const corners = utils.corners;
const Vec3 = utils.Vec3;

const std = @import("std");
const expect = std.testing.expect;
const expectErr = std.testing.expectError;

test "ndc perspective divide" {
    for (0..corners.len) |i| {
        const x_proj = try corners[i].x_projection();
        const y_proj = try corners[i].y_projection();

        const x_proj_remap = try corners[i].ndc_x_projection();
        const y_proj_remap = try corners[i].ndc_y_projection();

        try expect(x_proj_remap == ((1 + x_proj) / 2));
        try expect(y_proj_remap == ((1 + y_proj) / 2));
    }
}
