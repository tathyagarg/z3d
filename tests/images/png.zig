const z3d = @import("z3d");
const std = @import("std");

const _images = z3d.images;
const Image = _images.Image;

test "png" {
    var image = try Image.init("tests/assets/textures/texture01.png");
    defer image.deinit();
}
