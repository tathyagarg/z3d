const math = @import("../core/math/all.zig");

pub const FitResolutionGate = enum {
    kFill,
    kOverscan,
};

pub fn compute_screen_coordinates(
    aperture_width: f32,
    aperture_height: f32,
    screen_width: u32,
    screen_height: u32,
    fit: FitResolutionGate,
    near: f32,
    focal_length: f32,
) struct {
    top: f32,
    right: f32,
    bottom: f32,
    left: f32,
} {
    const film_aspect_ratio = aperture_width / aperture_height;
    const device_aspect_ratio = @as(f32, @floatFromInt(screen_width)) /
        @as(f32, @floatFromInt(screen_height));

    const two: f32 = 2;

    var top = @as(f32, @floatCast((aperture_height * (math.INCH_TO_MM / two)) / focal_length * near));
    var right = @as(f32, @floatCast((aperture_width * (math.INCH_TO_MM / two)) / focal_length * near));

    var xscale: f32 = 1;
    var yscale: f32 = 1;

    switch (fit) {
        .kFill => {
            if (film_aspect_ratio > device_aspect_ratio) {
                xscale = device_aspect_ratio / film_aspect_ratio;
            } else {
                yscale = film_aspect_ratio / device_aspect_ratio;
            }
        },
        .kOverscan => {
            if (film_aspect_ratio > device_aspect_ratio) {
                yscale = film_aspect_ratio / device_aspect_ratio;
            } else {
                xscale = device_aspect_ratio / film_aspect_ratio;
            }
        },
    }

    right *= xscale;
    top *= yscale;

    const bottom = -top;
    const left = -right;

    return .{
        .top = top,
        .right = right,
        .bottom = bottom,
        .left = left,
    };
}
