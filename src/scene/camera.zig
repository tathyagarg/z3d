const prims = @import("../core/math/primitives.zig");
const Scene = @import("scene.zig").Scene;
const ziglog = @import("ziglog");
const std = @import("std");

const constants = @import("../core/constants.zig");

const CANVAS_SIZE_X = constants.CANVAS_SIZE_X;
const CANVAS_SIZE_Y = constants.CANVAS_SIZE_Y;
const CANVAS_PIXEL_COUNT = constants.CANVAS_PIXEL_COUNT;

pub const CameraOptions = struct {
    near_plane: f32,
    far_plane: f32,
    right: f32,
    left: f32,
    top: f32,
    bottom: f32,
};

pub const Camera = struct {
    position: prims.Vec3,
    orientation: prims.Quaternion,

    /// FOV here is in degrees
    fov: prims.Vec2,
    canvas_size: prims.Vec2,
    canvas: [CANVAS_PIXEL_COUNT]prims.Color4,

    options: CameraOptions,
    /// The projection matrix is from Matrix4.projection_matrix
    projection_matrix: prims.Matrix4,

    pub fn init(scene: Scene) !Camera {
        const canvas_size = prims.Vec2{ .x = CANVAS_SIZE_X, .y = CANVAS_SIZE_Y };

        var canvas: [CANVAS_PIXEL_COUNT]prims.Color4 = undefined;
        for (0..CANVAS_PIXEL_COUNT) |i| {
            canvas[i] = scene.background_color;
        }

        const options = CameraOptions{
            .near_plane = 0.1,
            .far_plane = 1000.0,
            .top = CANVAS_SIZE_Y / 2,
            .bottom = -CANVAS_SIZE_Y / 2,
            .left = CANVAS_SIZE_X / 2,
            .right = -CANVAS_SIZE_X / 2,
        };

        return Camera{
            .position = prims.Vec3{ .x = 0, .y = 0, .z = 0 },
            .orientation = prims.Quaternion.identity(),
            .fov = prims.Vec2{ .x = 90, .y = 70 },
            .canvas_size = canvas_size,
            .canvas = canvas,
            .options = options,
            .projection_matrix = prims.Matrix4.projection_matrix(options),
        };
    }
};
