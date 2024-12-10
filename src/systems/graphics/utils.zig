const std = @import("std");
const math = @import("../../core/math/math.zig");
const float = @import("../../core/constants.zig").FLOAT;
const Ray = @import("ray.zig").Ray;
const Object = @import("objects/object.zig").Object;
const Light = @import("graphics.zig").Light;

const Vec3 = math.Vec3;
const Vec2 = math.Vec2;

const Vec3f = math.Vec3(float);
const Vec2f = math.Vec2(float);

const ArrayList = @import("std").ArrayList;

pub const FitResolutionGate = enum {
    kFill,
    kOverscan,
};

pub fn compute_screen_coordinates(
    aperture_width: float,
    aperture_height: float,
    screen_width: usize,
    screen_height: usize,
    fit: FitResolutionGate,
    near: float,
    focal_length: float,
) struct {
    top: float,
    right: float,
    bottom: float,
    left: float,
} {
    const film_aspect_ratio: float = aperture_width / aperture_height;
    const device_aspect_ratio: float = @as(float, @floatFromInt(screen_width)) /
        @as(float, @floatFromInt(screen_height));

    const two: float = 2;

    var top: float = @as(float, @floatCast((aperture_height * (math.INCH_TO_MM / two)) / focal_length * near));
    var right: float = @as(float, @floatCast((aperture_width * (math.INCH_TO_MM / two)) / focal_length * near));

    var xscale: float = 1;
    var yscale: float = 1;

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

    const bottom: float = -top;
    const left: float = -right;

    return .{
        .top = top,
        .right = right,
        .bottom = bottom,
        .left = left,
    };
}

pub const RayCastingOptions = struct {
    width: usize = 400,
    height: usize = 400,
    // In degrees
    fov: float = 90,
    max_depth: usize = 5,
    background_color: Vec3f = math.rgb_to_vec3f(float, 250, 249, 246),
    bias: float = 0.00001,

    near_plane: float = 0.5,
    far_plane: float = 100.0,
};

pub fn cast_ray(
    ray: Ray,
    objects: *ArrayList(Object),
    lights: *ArrayList(Light),
    options: *const RayCastingOptions,
    depth: usize,
) Vec3f {
    // ========================= DO NOT TOUCH ==========================
    // I have no idea on what the fuck it does and how the fuck it works.
    // Please, spare yourself the kajillion debugging hours.
    // =================================================================

    if (depth > options.max_depth) {
        return options.background_color;
    }

    var hit_color: Vec3f = options.background_color;
    var t_near: float = std.math.inf(float);
    var uv: Vec2f = undefined;
    var index: usize = 0;

    var hit_object: Object = undefined;
    var hit: bool = false;
    if (ray.trace(objects, &t_near, &index, &uv, &hit_object)) {
        if (t_near > options.far_plane or t_near < options.near_plane) return options.background_color;

        hit = true;
        const hit_point: Vec3f = ray.at(t_near);
        var normal: Vec3f = undefined;
        var texture: Vec2f = undefined;
        hit_object.get_surface_props(
            &hit_point,
            &ray.direction,
            index,
            &uv,
            &normal,
            &texture,
        );

        // var temp = hit_point;
        const material = hit_object.get_material();
        switch (material.material_type) {
            .REFLECTION_AND_REFRACTION => {
                const reflection_direction = ray.reflection(normal).normalize();
                const refraction_direction = ray.refraction(normal, material.ior);

                const a = hit_point.subtract(normal.multiply(options.bias));
                const b = hit_point.add(normal.multiply(options.bias));

                const reflection_ray_origin = if (reflection_direction.dot(normal) < 0) a else b;
                const refraction_ray_origin = if (refraction_direction.dot(normal) < 0) a else b;

                const reflection_color = cast_ray(
                    Ray{
                        .origin = reflection_ray_origin,
                        .direction = reflection_direction,
                    },
                    objects,
                    lights,
                    options,
                    depth + 1,
                );

                const refraction_color = cast_ray(
                    Ray{
                        .origin = refraction_ray_origin,
                        .direction = refraction_direction,
                    },
                    objects,
                    lights,
                    options,
                    depth + 1,
                );

                var kr: float = undefined;
                ray.fresnel(normal, material.ior, &kr);
                hit_color = reflection_color.mix(refraction_color, 1 - kr);
            },
            .REFLECTION => {
                var kr: float = undefined;
                ray.fresnel(normal, material.ior, &kr);

                const reflection_direction = ray.reflection(normal);
                const reflection_ray_origin = if (reflection_direction.dot(normal) < 0) hit_point.add(normal.multiply(options.bias)) else hit_point.subtract(normal.multiply(options.bias));

                hit_color = cast_ray(
                    Ray{
                        .origin = reflection_ray_origin,
                        .direction = reflection_direction,
                    },
                    objects,
                    lights,
                    options,
                    depth + 1,
                ).multiply(kr);
            },
            .DIFFUSE_AND_GLOSSY => {
                var light_amount: Vec3f = Vec3f.zero();
                var specular_color: Vec3f = Vec3f.zero();

                const shadow_point_origin = if (ray.direction.dot(normal) < 0) hit_point.add(normal.multiply(options.bias)) else hit_point.subtract(normal.multiply(options.bias));
                for (lights.items) |light| {
                    var light_direction = light.position.subtract(hit_point);
                    const light_dist_sqr = light_direction.dot(light_direction);

                    light_direction = light_direction.normalize();
                    const LdotN = @max(0, light_direction.dot(normal));
                    var shadow_hit_obj: Object = undefined;
                    var t_near_shadow: float = std.math.inf(float);

                    const in_shadow = @intFromBool((Ray{
                        .origin = shadow_point_origin,
                        .direction = light_direction,
                    }).trace(
                        objects,
                        &t_near_shadow,
                        &index,
                        &uv,
                        &shadow_hit_obj,
                    ) and (t_near_shadow * t_near_shadow < light_dist_sqr));

                    light_amount = light_amount
                        .add(light.intensity
                        .multiply(LdotN)
                        .multiply(@as(float, @floatFromInt(1 - in_shadow))));
                    const pre_reflection_direction = Ray{ .origin = Vec3f.zero(), .direction = light_direction.negate() };
                    const reflection_direction = pre_reflection_direction.reflection(normal);
                    specular_color = specular_color.add(
                        light.intensity.multiply(
                            std.math.pow(
                                float,
                                @max(0, -reflection_direction.dot(ray.direction)),
                                hit_object.get_material().specular_exponent,
                            ),
                        ),
                    );
                }
                hit_color = hit_object
                    .eval_diffuse_color(texture)
                    .direct_multiplication(light_amount)
                    .multiply(material.kd)
                    .add(specular_color.multiply(material.ks));
            },
        }
    }

    return hit_color;
}
