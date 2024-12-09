const graphics = @import("../systems/graphics/graphics.zig");
const math = @import("../core/math/math.zig");
const constants = @import("../core/constants.zig");

const float = constants.FLOAT;

const ArrayList = @import("std").ArrayList;

const Object = graphics.objects.Object;
const Light = graphics.Light;
const RayCastingOptions = graphics.RayCastingOptions;
const Ray = graphics.Ray;

const Vec3 = math.Vec3;
const Vec3f = Vec3(float);

pub const Scene = struct {
    label: []const u8,
    objects: *ArrayList(Object),
    lights: *ArrayList(Light),
    ray_casting_options: *const RayCastingOptions,

    const Self = @This();

    pub fn init(
        objects: *ArrayList(Object),
        lights: *ArrayList(Light),
        options: struct {
            label: []const u8 = "Untitled Scene",
            ray_casting_options: *const RayCastingOptions = &RayCastingOptions{},
        },
    ) Self {
        return Self{
            .objects = objects,
            .lights = lights,
            .label = options.label,
            .ray_casting_options = options.ray_casting_options,
        };
    }

    pub fn render(self: Self, frame_buffer: *[]Vec3f) void {
        const scale: float = @tan(math.DEG_TO_RAD * self.ray_casting_options.fov * 0.5);
        const screen_aspect_ratio: float =
            @as(float, @floatFromInt(self.ray_casting_options.width)) /
            @as(float, @floatFromInt(self.ray_casting_options.height));

        const origin = Vec3f.diagonal(-1);

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

                const direction = Vec3f.init(x, y, -1).normalize();
                const ray = Ray{ .origin = origin, .direction = direction };
                frame_buffer.*[j * self.ray_casting_options.width + i] =
                    graphics.cast_ray(
                    ray,
                    self.objects,
                    self.lights,
                    self.ray_casting_options,
                    0,
                );
            }
        }
    }
};
