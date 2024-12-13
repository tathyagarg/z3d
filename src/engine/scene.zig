const std = @import("std");
const graphics = @import("../systems/graphics/graphics.zig");
const math = @import("../core/math/math.zig");
const constants = @import("../core/constants.zig");

const float = constants.FLOAT;

const ArrayList = @import("std").ArrayList;

const Object = graphics.objects.Object;
const Light = graphics.Light;
const RayCastingOptions = graphics.RayCastingOptions;
const Ray = graphics.Ray;
const Camera = @import("camera.zig").Camera;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);

const RGB = @import("../systems/graphics/graphics.zig").RGB;

pub const Scene = struct {
    label: []const u8,
    objects: *ArrayList(Object),
    lights: *ArrayList(Light),
    ray_casting_options: *const RayCastingOptions,
    camera: Camera,

    const Self = @This();

    pub fn init(
        camera: Camera,
        objects: *ArrayList(Object),
        lights: *ArrayList(Light),
        options: struct {
            label: []const u8 = "Untitled Scene",
            ray_casting_options: *const RayCastingOptions = &RayCastingOptions{},
        },
    ) Self {
        return Self{
            .camera = camera,
            .objects = objects,
            .lights = lights,
            .label = options.label,
            .ray_casting_options = options.ray_casting_options,
        };
    }

    pub fn render(self: Self, frame_buffer: *[]RGB) void {
        const scale: float = @tan(math.DEG_TO_RAD * self.ray_casting_options.fov * 0.5);
        const screen_aspect_ratio: float =
            @as(float, @floatFromInt(self.ray_casting_options.width)) /
            @as(float, @floatFromInt(self.ray_casting_options.height));

        for (0..self.ray_casting_options.height) |j| {
            for (0..self.ray_casting_options.width) |i| {
                const x: float =
                    (2 * (@as(float, @floatFromInt(i)) + 0.5) /
                    @as(float, @floatFromInt(self.ray_casting_options.width)) - 1) *
                    screen_aspect_ratio * scale;

                const y: float =
                    (1 - 2 * (@as(f32, @floatFromInt(j)) + 0.5) /
                    @as(float, @floatFromInt(self.ray_casting_options.height))) *
                    scale;

                const direction = self.camera.get_direction(x, y).normalize();
                const ray = Ray{
                    .origin = self.camera.position,
                    .direction = direction,
                };

                const curr_pixel = RGB.vec_to_rgb(graphics.cast_ray(
                    ray,
                    self.objects,
                    self.lights,
                    self.ray_casting_options,
                    0,
                ));

                frame_buffer.*[j * self.ray_casting_options.width + i] = curr_pixel;
            }
        }
    }
};
