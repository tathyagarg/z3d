// This is a program to convert the points in a 3D .obj file (assets/xtree.obj) to a .svg file
const z3d = @import("z3d");
const std = @import("std");

const Vec3 = z3d.math.Vec3f32;
const Vec3i32 = z3d.math.Vec3i32;
const Mat4 = z3d.math.Mat4f32;

const ArrayList = std.ArrayList;
const allocator = std.testing.allocator;

test "compute pixel coordinates" {
    const computation_constants = .{
        .canvas_width = 2,
        .canvas_height = 2,
        .screen_width = 512,
        .screen_height = 512,
    };
    const line_string = "<line x1=\"{d}\" y1=\"{d}\" x2=\"{d}\" y2=\"{d}\" style=\"stroke:rgb(0, 0, 0); stroke-width: 1\" />\n";

    var vertices = ArrayList(Vec3).init(allocator);
    defer vertices.deinit();

    // This isn't really the intended use of Vec3, but I don't really care.
    var faces = ArrayList(Vec3i32).init(allocator);
    defer faces.deinit();

    var assets_dir = try std.fs.cwd().openDir("assets", .{});
    defer assets_dir.close();

    // http://www.scratchapixel.com/lessons/3d-basic-rendering/computing-pixel-coordinates-of-3d-point
    const obj = try assets_dir.openFile("xtree.obj", .{});
    defer obj.close();

    var buffer: [64]u8 = undefined;
    while (true) {
        _ = obj.reader().readUntilDelimiter(buffer[0..buffer.len], 10) catch break; // 10 stands for the newline character

        var iter = std.mem.splitScalar(u8, buffer[2..buffer.len], 32); // 32 stands for space character

        if (buffer[0] == 'v') {
            const x = try std.fmt.parseFloat(f32, iter.next().?);
            const y = try std.fmt.parseFloat(f32, iter.next().?);
            const z = try std.fmt.parseFloat(f32, iter.next().?);
            try vertices.append(Vec3.init(x, y, z));
        } else {
            const x = try std.fmt.parseInt(i32, iter.next().?, 0);
            const y = try std.fmt.parseInt(i32, iter.next().?, 0);
            const z = try std.fmt.parseInt(i32, iter.next().?, 0);
            // Subtract 1 to convert from 1-indexed to 0-indexed values
            try faces.append(Vec3i32.init(x - 1, y - 1, z - 1));
        }
    }

    var outputs = try std.fs.cwd().openDir("tests/outputs", .{});
    defer outputs.close();

    const svg = try outputs.createFile("xtree.svg", .{});
    defer svg.close();

    _ = try svg.write("<svg version=\"1.1\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" xmlns=\"http://www.w3.org/2000/svg\" height=\"512\" width=\"512\">");

    const camera_to_world = Mat4.from([4][4]f32{
        .{ 0.871214, 0, -0.490904, 0 },
        .{ -0.192902, 0.919559, -0.342346, 0 },
        .{ 0.451415, 0.392953, 0.801132, 0 },
        .{ 14.777467, 29.361945, 27.993464, 1 },
    });
    const world_to_camera = camera_to_world.inverse();

    for (faces.items) |face| {
        const v0world = vertices.items[@as(usize, @intCast(face.x))];
        const v1world = vertices.items[@as(usize, @intCast(face.y))];
        const v2world = vertices.items[@as(usize, @intCast(face.z))];

        const v0raster = try v0world.compute_pixel_coords(
            world_to_camera,
            computation_constants,
        );
        const v1raster = try v1world.compute_pixel_coords(
            world_to_camera,
            computation_constants,
        );
        const v2raster = try v2world.compute_pixel_coords(
            world_to_camera,
            computation_constants,
        );

        const v01 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v0raster.x, v0raster.y, v1raster.x, v1raster.y },
        );
        defer std.testing.allocator.free(v01);

        const v12 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v1raster.x, v1raster.y, v2raster.x, v2raster.y },
        );
        defer std.testing.allocator.free(v12);

        const v02 = try std.fmt.allocPrint(
            std.testing.allocator,
            line_string,
            .{ v0raster.x, v0raster.y, v2raster.x, v2raster.y },
        );
        defer std.testing.allocator.free(v02);

        _ = try svg.write(v01);
        _ = try svg.write(v12);
        _ = try svg.write(v02);
    }

    _ = try svg.write("</svg>\n");
}
