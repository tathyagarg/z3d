const std = @import("std");
const print = std.debug.print;

const app = @import("app.zig");

pub fn main() !void {
    var w = app.Application.init("Cell Atom Simulator") catch {
        return;
    };
    try w.mainloop();
}
