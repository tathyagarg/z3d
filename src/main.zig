const std = @import("std");
const print = std.debug.print;

const app = @import("core/app.zig");
const ziglog = @import("ziglog");

pub fn main() !void {
    const logger = try ziglog.Logger.get(.{});

    try logger.debug("Initializing application.");
    var w = app.Application.init("Z3D") catch {
        return;
    };
    try w.mainloop();
    try logger.debug("Initialization complete");
}
