const ziglog = @import("ziglog");

test "all" {
    // Initialize a tests logger
    _ = try ziglog.Logger.get(.{
        .name = "tests",
        .sink = .file,
        .file_path = ".tests.log",
        .format_string = "{message}",
    });

    // Basic projections
    _ = @import("basics_projection/perspective_divide.zig");
    _ = @import("basics_projection/ndc_perspective_divide.zig");
    _ = @import("basics_projection/raster_perspective_divide.zig");

    // Geometry
    _ = @import("geometry/subtraction.zig");
    _ = @import("geometry/cross_product.zig");
    _ = @import("geometry/change_handedness.zig");

    _ = @import("computing_pixel_coords.zig");
}
