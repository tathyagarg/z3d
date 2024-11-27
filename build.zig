const Build = @import("std").Build;

pub fn build(b: *Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "atom",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const ziglog = b.dependency("ziglog", .{
        .target = target,
        .optimize = optimize,
    });
    exe.root_module.addImport("ziglog", ziglog.module("ziglog"));

    if (target.result.os.tag == .linux) {
        // The SDL package doesn't work for Linux yet, so we rely on system
        // packages for now.
        exe.linkSystemLibrary("SDL2");
        exe.linkLibC();
    } else {
        const sdl_dep = b.dependency("SDL", .{
            .optimize = .ReleaseFast,
            .target = target,
        });
        exe.linkLibrary(sdl_dep.artifact("SDL2"));
    }

    b.installArtifact(exe);

    const run = b.step("run", "Run the demo");
    const run_cmd = b.addRunArtifact(exe);
    run.dependOn(&run_cmd.step);
}
