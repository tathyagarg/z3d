const std = @import("std");
const math = @import("../core/math/all.zig");
const Ray = @import("ray.zig").Ray;
const Object = @import("objects/object.zig").Object;
const Light = @import("light.zig").Light;
const Vec3 = @import("../core/math/all.zig").Vec3;
const Vec2 = @import("../core/math/all.zig").Vec2;
const ArrayList = @import("std").ArrayList;

pub const FitResolutionGate = enum {
    kFill,
    kOverscan,
};

pub fn compute_screen_coordinates(
    aperture_width: f32,
    aperture_height: f32,
    screen_width: u32,
    screen_height: u32,
    fit: FitResolutionGate,
    near: f32,
    focal_length: f32,
) struct {
    top: f32,
    right: f32,
    bottom: f32,
    left: f32,
} {
    const film_aspect_ratio = aperture_width / aperture_height;
    const device_aspect_ratio = @as(f32, @floatFromInt(screen_width)) /
        @as(f32, @floatFromInt(screen_height));

    const two: f32 = 2;

    var top = @as(f32, @floatCast((aperture_height * (math.INCH_TO_MM / two)) / focal_length * near));
    var right = @as(f32, @floatCast((aperture_width * (math.INCH_TO_MM / two)) / focal_length * near));

    var xscale: f32 = 1;
    var yscale: f32 = 1;

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

    const bottom = -top;
    const left = -right;

    return .{
        .top = top,
        .right = right,
        .bottom = bottom,
        .left = left,
    };
}

pub const RayCastingOptions = struct {
    width: u32,
    height: u32,
    fov: f32,
    max_depth: u32,
    background_color: Vec3(f32),
    bias: f32,
};

pub fn cast_ray(
    ray: Ray,
    objects: ArrayList(Object),
    lights: ArrayList(Light),
    options: RayCastingOptions,
    depth: u32,
    x: usize,
    y: usize,
) Vec3(f32) {
    if (depth > options.max_depth) {
        return options.background_color;
    }

    var hit_color = options.background_color;
    var t_near: f32 = std.math.inf(f32);
    var uv: math.Vec2f32 = undefined;
    var index: usize = 0;

    var hit_object: Object = undefined;
    var hit = false;
    if (ray.trace(&objects, &t_near, &index, &uv, &hit_object, x, y)) {
        hit = true;
        const hit_point = ray.at(t_near);
        var normal: math.Vec3f32 = undefined;
        var texture: math.Vec2f32 = undefined;
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
                    x,
                    y,
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
                    x,
                    y,
                );

                var kr: f32 = undefined;
                ray.fresnel(normal, material.ior, &kr);
                hit_color = reflection_color.mix(refraction_color, kr);
            },
            .REFLECTION => {
                var kr: f32 = undefined;
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
                    x,
                    y,
                ).multiply(kr);
            },
            .DIFFUSE_AND_GLOSSY => {
                var light_amount: Vec3(f32) = Vec3(f32).zero();
                var specular_color: Vec3(f32) = Vec3(f32).zero();

                const shadow_point_origin = if (ray.direction.dot(normal) < 0) hit_point.add(normal.multiply(options.bias)) else hit_point.subtract(normal.multiply(options.bias));
                for (lights.items) |light| {
                    var light_direction = light.position.subtract(hit_point);
                    const light_dist_sqr = light_direction.dot(light_direction);

                    light_direction = light_direction.normalize();
                    const LdotN = @max(0, light_direction.dot(normal));
                    var shadow_hit_obj: Object = undefined;
                    var t_near_shadow: f32 = undefined;

                    const in_shadow = @intFromBool((Ray{
                        .origin = shadow_point_origin,
                        .direction = light_direction,
                    }).trace(
                        &objects,
                        &t_near_shadow,
                        &index,
                        &uv,
                        &shadow_hit_obj,
                        x,
                        y,
                    ) and (t_near_shadow * t_near_shadow < light_dist_sqr));

                    light_amount = light_amount
                        .add(light.intensity
                        .multiply(LdotN)
                        .multiply(@as(f32, @floatFromInt(1 - in_shadow))));
                    const pre_reflection_direction = Ray{ .origin = Vec3(f32).zero(), .direction = light_direction.negate() };
                    const reflection_direction = pre_reflection_direction.reflection(normal);
                    specular_color = specular_color.add(
                        light.intensity.multiply(
                            std.math.pow(
                                f32,
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
    if (hit and x == 320 and y == 218) {
        std.debug.print("{any} {d} {d} {d} {d}\n", .{
            hit_object.get_material().material_type,
            hit_color.x,
            hit_color.y,
            hit_color.z,
            depth,
        });
    }

    return hit_color;
}
