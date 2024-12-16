const std = @import("std");

const targets: []const std.Target.Query = &.{
    .{ .cpu_arch = .aarch64, .os_tag = .macos },
    .{ .cpu_arch = .aarch64, .os_tag = .linux },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .gnu },
    .{ .cpu_arch = .x86_64, .os_tag = .linux, .abi = .musl },
    .{ .cpu_arch = .x86_64, .os_tag = .windows },
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const all_targets = b.option(bool, "all-targets", "Build for all targets") orelse false;

    if (all_targets) {
        for (targets) |t| {
            const exe = b.addExecutable(.{
                .name = "z3d",
                .root_source_file = b.path("src/main.zig"),
                .target = b.resolveTargetQuery(t),
                .optimize = optimize,
            });

            if (b.resolveTargetQuery(t).result.os.tag == .linux) {
                exe.linkSystemLibrary("SDL2");
                exe.linkLibC();
            } else {
                const sdl_dep = b.dependency("SDL2", .{
                    .optimize = .ReleaseFast,
                    .target = b.resolveTargetQuery(t),
                });
                exe.linkLibrary(sdl_dep.artifact("SDL2"));
            }
            exe.linkSystemLibrary("GL");

            const target_out = b.addInstallArtifact(exe, .{ .dest_dir = .{ .override = .{
                .custom = try t.zigTriple(b.allocator),
            } } });

            if (t.cpu_arch == .x86_64 and t.os_tag == .linux and t.abi == .gnu) {
                const runner = b.addRunArtifact(exe);
                const run_step = b.step("run", "Run the application");
                run_step.dependOn(&runner.step);
            }

            b.getInstallStep().dependOn(&target_out.step);
        }
    } else {
        const exe = b.addExecutable(.{
            .name = "z3d",
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        });

        exe.linkSystemLibrary("SDL2");
        exe.linkSystemLibrary("GL");
        exe.linkLibC();

        const target_out = b.addInstallArtifact(exe, .{});

        const runner = b.addRunArtifact(exe);
        const run_step = b.step("run", "Run the application");
        run_step.dependOn(&runner.step);

        b.getInstallStep().dependOn(&target_out.step);
    }

    const exe_unit_tests = b.addTest(.{
        .root_source_file = b.path("tests/all.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_unit_tests.root_module.addImport("z3d", b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
    }));

    if (target.result.os.tag == .linux) {
        exe_unit_tests.linkSystemLibrary("SDL2");
        exe_unit_tests.linkLibC();
    } else {
        const sdl_dep = b.dependency("SDL2", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        exe_unit_tests.linkLibrary(sdl_dep.artifact("SDL2"));
    }
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
