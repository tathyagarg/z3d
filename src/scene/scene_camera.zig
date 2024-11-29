const prims = @import("../core/math/primitives.zig");

pub const SceneCamera = struct {
    position: prims.Vec3,
    orientation: prims.Quaternion,

    fov: struct { x: i32, y: i32 },

    /// The projection matrix is from Matrix4.projection_matrix
    projection_matrix: prims.Matrix4,
};
