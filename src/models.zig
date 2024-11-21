const bufPrint = @import("std").fmt.bufPrint;

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,

    const Self = @This();

    pub fn init(r: u8, g: u8, b: u8, a: ?u8) Self {
        return Color{ .r = r, .g = g, .b = b, .a = a orelse 255 };
    }

    pub fn hex(self: Self) ![]const u8 {
        var buffer: [7]u8 = undefined;
        const len = bufPrint(&buffer, "#{02X}{02X}{02X}", .{ self.r, self.g, self.b });
        return buffer[0..len];
    }

    pub fn equals(self: Self, other: Self) bool {
        return self.r == other.r and self.g == other.g and self.b == other.b;
    }

    pub const BLACK = Color.init(0, 0, 0, 255);
    pub const WHITE = Color.init(255, 255, 255, 255);
    pub const RED = Color.init(255, 0, 0, 255);
};

pub const Position = struct {
    x: u64,
    y: u64,
    z: u64,

    const Self = @This();

    pub fn init(x: u64, y: u64, z: u64) Self {
        return Position{ .x = x, .y = y, .z = z };
    }
};
