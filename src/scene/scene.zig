const Camera = @import("camera.zig").Camera;
const prims = @import("../core/math/primitives.zig");

pub const Scene = struct {
    camera: Camera = undefined,
    background_color: prims.Color4 = prims.BLACK,

    // Change from i32 to object later
    objects: []i32 = &[_]i32{},

    pub fn init() Scene {
        var scene = Scene{};
        const camera = Camera.init(scene);
        scene.camera = camera;

        return scene;
    }
};
