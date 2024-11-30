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
    canvas_size: prims.Vec2i,
    focal_length: f32,

    /// prims.Vec2 of the camera's Field of View (FOV) in radians
    /// The FOV is given by the formulae:
    /// fov_x = 2 * atan( width / (2 * focal_length) )
    /// fov_y = 2 * atan( height / (2 * focal_length) )
    ///
    /// Where width is the width of the canvas, and height is the height of the canvas.
    ///
    /// Learn more:
    /// https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/perspective-matrix-in-practice.html
    fov: prims.Vec2 = undefined,
    points: struct { top: f32, right: f32, bottom: f32, left: f32 } = undefined,

    pub fn init(
        near_plane: f32,
        far_plane: f32,
        canvas_size: prims.Vec2i,
        focal_length: f32,
    ) CameraOptions {
        const fov_x = 2 * std.math.atan(@as(f32, @floatFromInt(canvas_size.x)) / (2 * focal_length));
        const fov_y = 2 * std.math.atan(@as(f32, @floatFromInt(canvas_size.y)) / (2 * focal_length));

        const right = std.math.tan(fov_x / 2) * near_plane;
        const left = -right;
        const top = (right - left) / (@as(f32, @floatFromInt(canvas_size.x)) / @as(f32, @floatFromInt(canvas_size.y))) / 2;
        const bottom = -top;

        return CameraOptions{
            .near_plane = near_plane,
            .far_plane = far_plane,
            .canvas_size = canvas_size,
            .focal_length = focal_length,
            .fov = prims.Vec2{
                .x = fov_x,
                .y = fov_y,
            },
            .points = .{
                .top = top,
                .right = right,
                .bottom = bottom,
                .left = left,
            },
        };
    }
};

pub const Camera = struct {
    position: prims.Vec3,
    orientation: prims.Quaternion,

    canvas_size: prims.Vec2i,
    canvas: [CANVAS_PIXEL_COUNT]prims.Color4,

    options: CameraOptions,
    /// The projection matrix is from Matrix4.projection_matrix
    projection_matrix: prims.Matrix4,

    pub fn init(scene: Scene) !Camera {
        const canvas_size = prims.Vec2i{ .x = CANVAS_SIZE_X, .y = CANVAS_SIZE_Y };

        var canvas: [CANVAS_PIXEL_COUNT]prims.Color4 = undefined;
        for (0..CANVAS_PIXEL_COUNT) |i| {
            canvas[i] = scene.background_color;
        }

        const options = CameraOptions.init(1.0, 1000.0, canvas_size, 1);

        return Camera{
            .position = prims.Vec3{ .x = 0, .y = 0, .z = 0 },
            .orientation = prims.Quaternion.identity(),
            .canvas_size = canvas_size,
            .canvas = canvas,
            .options = options,
            .projection_matrix = prims.Matrix4.projection_matrix(options),
        };
    }

    pub fn render(self: Camera) ![CANVAS_PIXEL_COUNT]prims.Color4 {
        // const logger = try ziglog.Logger.get(.{ .name = "console" });

        const scale_x: f32 = std.math.tan(self.options.fov.x / 2);
        const scale_y: f32 = std.math.tan(self.options.fov.y / 2);

        const canvas_x: usize = @intCast(self.canvas_size.x);
        const canvas_y: usize = @intCast(self.canvas_size.y);

        var canvas: [CANVAS_PIXEL_COUNT]prims.Color4 = undefined;

        // try logger.debug(try std.fmt.allocPrint(
        //     std.heap.page_allocator,
        //     "X: {d} Y: {d} SIZE: {d}",
        //     .{ canvas_x, canvas_y, CANVAS_PIXEL_COUNT },
        // ));

        for (0..(canvas_x - 1)) |x| {
            for (0..(canvas_y - 1)) |y| {
                const x_coord: f32 = (2 * (@as(f32, @floatFromInt(x)) + 0.5) /
                    (@as(f32, @floatFromInt(self.canvas_size.x)) - 1)) *
                    scale_x;

                const y_coord: f32 = (2 * (@as(f32, @floatFromInt(y)) + 0.5) /
                    (@as(f32, @floatFromInt(self.canvas_size.y)) - 1)) *
                    scale_y;

                const unnormalized_direction = (prims.Vec3{ .x = x_coord, .y = y_coord, .z = -1 });
                const direction = unnormalized_direction.normalize();

                // try logger.debug(try std.fmt.allocPrint(
                //     std.heap.page_allocator,
                //     "X: {d} Y: {d} P: {d}",
                //     .{ x, y, x * canvas_y + y },
                // ));
                canvas[(x * canvas_y) + y] = try cast_ray(direction);
            }
        }

        return canvas;
    }
};

pub fn cast_ray(direction: prims.Vec3) !prims.Color4 {
    // const logger = try ziglog.Logger.get(.{ .name = "console" });
    // try logger.debug(try std.fmt.allocPrint(
    //     std.heap.page_allocator,
    //     "X: {d}",
    //     .{@as(u8, @intFromFloat(direction.x * 255))},
    // ));

    return prims.Color4{
        .r = @as(u8, @intFromFloat(direction.x * 255)),
        .g = @as(u8, @intFromFloat(direction.y * 255)),
        .b = @as(u8, @intFromFloat(direction.z * -255)),
        .a = 100,
    };
}
