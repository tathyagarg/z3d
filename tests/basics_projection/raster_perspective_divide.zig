const constants = @import("z3d").constants;
const utils = @import("utils.zig");

const corners = utils.corners;
const Vec3 = utils.Vec3;

const std = @import("std");
const expect = std.testing.expect;
const expectErr = std.testing.expectError;

test "raster perspective divide" {
    for (0..corners.len) |i| {
        const x_proj_remap = try corners[i].ndc_x_projection();
        const y_proj_remap = try corners[i].ndc_y_projection();

        const x_proj_raster = try corners[i].raster_x_projection();
        const y_proj_raster = try corners[i].raster_y_projection();

        try expect(x_proj_raster == (x_proj_remap * constants.SCREEN_WIDTH));
        try expect(y_proj_raster == (y_proj_remap * constants.SCREEN_HEIGHT));
    }
}
