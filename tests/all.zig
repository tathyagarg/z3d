test "all" {
    // Basic projections
    // _ = @import("basics_projection/perspective_divide.zig");
    // _ = @import("basics_projection/ndc_perspective_divide.zig");
    // _ = @import("basics_projection/raster_perspective_divide.zig");

    // Geometry
    _ = @import("geometry/subtraction.zig");
    _ = @import("geometry/cross_product.zig");
    _ = @import("geometry/change_handedness.zig");

    // .obj to .svg
    // This test does not work anymore due to a change in the params of the Vec3.computing_pixel_coords function
    // _ = @import("obj_conversion/computing_pixel_coords.zig");
    // _ = @import("obj_conversion/pinhole_camera.zig");
    // _ = @import("obj_conversion/rasterization.zig");
    _ = @import("obj_conversion/projection_matrix.zig");

    // Ray casting
    // _ = @import("ray-casting/whitted.zig");

    // Scene rendering
    // _ = @import("scene/basic.zig");
    // _ = @import("scene/physics.zig");

    // Windows
    // _ = @import("windows/window_init.zig");

    // Images
    _ = @import("images/png.zig");

    // Engine
    // _ = @import("engine/test01.zig");
}
