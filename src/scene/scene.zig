const SceneCamera = @import("scene_camera.zig").SceneCamera;

pub const Scene = struct {
    camera: SceneCamera,

    // Change from i32 to object later
    objects: []i32,
};
