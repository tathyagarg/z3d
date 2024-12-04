pub const RGB = packed struct {
    r: u8,
    g: u8,
    b: u8,

    const Self = @This();

    pub fn init(r: u8, g: u8, b: u8) Self {
        return Self{ .r = r, .g = g, .b = b };
    }

    pub fn grayscale(value: u8) Self {
        return Self{ .r = value, .g = value, .b = value };
    }

    pub const WHITE = RGB{ .r = 255, .g = 255, .b = 255 };
    pub const BLACK = RGB{ .r = 0, .g = 0, .b = 0 };
};
