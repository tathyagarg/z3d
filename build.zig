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

    const exe = b.addExecutable(.{
        .name = "z3d",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    if (target.result.os.tag == .linux) {
        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("SDL2", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    // const gl_bindings = @import("zigglgen").generateBindingsModule(b, .{
    //     .api = .gl,
    //     .version = .@"4.1",
    //     .profile = .core,
    //     .extensions = &.{
    //         .ARB_clip_control,
    //         .NV_scissor_exclusive,
    //     },
    // });
    // exe.root_module.addImport("gl", gl_bindings);
    exe.addCSourceFile(.{ .file = b.path("include/glad/glad.c") });
    exe.addIncludePath(b.path("include/"));

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

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
    exe_unit_tests.addCSourceFile(.{ .file = b.path("include/glad/glad.c") });
    exe_unit_tests.addIncludePath(b.path("include/glad"));

    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
}
