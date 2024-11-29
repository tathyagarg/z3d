const std = @import("std");

const engine = @import("core/engine.zig");
const ziglog = @import("ziglog");

pub fn main() !void {
    const logger = try ziglog.Logger.get(.{ .sink = .file, .file_path = ".log", .name = "main" });
    _ = try ziglog.Logger.get(.{ .name = "console", .sink = .console });

    try logger.debug("Initializing application.");
    var w = try engine.Engine.init("Z3D");
    defer w.deinit();

    try w.mainloop();
    try logger.debug("Initialization complete");
}
