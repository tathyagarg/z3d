const sdl = @cImport(@cInclude("SDL2/SDL.h"));
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
const allocator = std.heap.page_allocator;

pub const RenderingOption = struct {
    x_start: usize = 0,
    y_start: usize = 0,
    x_end: usize = 0,
    y_end: usize = 0,
};

pub const Scene = struct {
    label: []const u8,
    objects: *ArrayList(Object),
    lights: *ArrayList(Light),
    ray_casting_options: *const RayCastingOptions,
    camera: Camera,

    cpu_count: usize,

    const Self = @This();

    pub fn init(
        camera: Camera,
        objects: *ArrayList(Object),
        lights: *ArrayList(Light),
        options: struct {
            label: []const u8 = "Untitled Scene",
            ray_casting_options: *const RayCastingOptions = &RayCastingOptions{},
            cpu_count: usize = 0,
        },
    ) !Self {
        return Self{
            .camera = camera,
            .objects = objects,
            .lights = lights,
            .label = options.label,
            .ray_casting_options = options.ray_casting_options,
            .cpu_count = if (options.cpu_count == 0) try std.Thread.getCpuCount() else options.cpu_count,
        };
    }

    pub fn handle_event(self: Self, event: sdl.SDL_Event) void {
        for (self.objects.items) |obj| {
            obj.handle_event(event);
        }
    }

    pub fn render_task(self: Self, frame_buffer: *[]RGB, rendering_options: RenderingOption) void {
        const scale: float = @tan(math.DEG_TO_RAD * self.ray_casting_options.fov * 0.5);
        const screen_aspect_ratio: float =
            @as(float, @floatFromInt(self.ray_casting_options.width)) /
            @as(float, @floatFromInt(self.ray_casting_options.height));

        const y_end = if (rendering_options.y_end == 0) self.ray_casting_options.height else rendering_options.y_end;
        const x_end = if (rendering_options.x_end == 0) self.ray_casting_options.width else rendering_options.x_end;

        for (rendering_options.y_start..y_end) |j| {
            for (rendering_options.x_start..x_end) |i| {
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
                    .origin = self.camera.position.single.point.*,
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

    pub fn render(self: Self, frame_buffer: *[]RGB) !void {
        if (self.cpu_count != 1) {
            var handles: std.ArrayList(std.Thread) = std.ArrayList(std.Thread).init(allocator);
            defer handles.deinit();

            const lines_per_thread = @divFloor(self.ray_casting_options.height, self.cpu_count);

            for (0..self.cpu_count) |i| {
                try handles.append(try std.Thread.spawn(.{}, Scene.render_task, .{
                    self,
                    frame_buffer,
                    RenderingOption{
                        .x_start = 0,
                        .y_start = i * lines_per_thread,
                        .x_end = self.ray_casting_options.width,
                        .y_end = (i + 1) * lines_per_thread,
                    },
                }));
            }

            for (handles.items) |h|
                h.join();
        } else {
            self.render_task(frame_buffer, RenderingOption{});
        }
    }
};
