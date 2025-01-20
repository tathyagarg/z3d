const std = @import("std");

const Image = @import("../images/images.zig").Image;
const RGB = @import("../graphics/graphics.zig").RGB;
const float = @import("../../core/constants.zig").FLOAT;
const allocator = std.heap.page_allocator;

const Vec2 = @import("../../core/math/math.zig").Vec2;
const Vec2f = Vec2(float);

pub const GUI_Bounds = struct {
    top_left: Vec2f,
    bottom_right: Vec2f,

    pub fn contains(self: GUI_Bounds, x: usize, y: usize) bool {
        // this might look weird until u realize (0, 0) is the top left corner
        const x_f: float = @floatFromInt(x);
        const y_f: float = @floatFromInt(y);
        const res = x_f >= self.top_left.x and x_f <= self.bottom_right.x and
            y_f >= self.top_left.y and y_f <= self.bottom_right.y;
        return res;
    }
};

pub const GUI_Text = struct {
    text: []const u8,
    font_size: u32,
    color: RGB,
    position: GUI_Bounds,
};

pub const GUI_Image = struct {
    image: Image,
    position: GUI_Bounds,
};

pub const GUI_Element = union(enum) {
    Image: GUI_Image,
    Text: GUI_Text,

    pub fn contains(self: GUI_Element, x: usize, y: usize) bool {
        switch (self) {
            .Image => return self.Image.position.contains(x, y),
            .Text => return self.Text.position.contains(x, y),
        }
    }

    pub fn render_at(self: GUI_Element, location: Vec2f) RGB {
        return switch (self) {
            .Image => |img| {
                return img.image.sample(location);
            },
            .Text => unreachable,
        };
    }

    pub fn to_local_space(self: GUI_Element, x: usize, y: usize) Vec2f {
        return switch (self) {
            .Image => |img| {
                return Vec2f.init(
                    @as(float, @floatFromInt(x)) - img.position.top_left.x,
                    @as(float, @floatFromInt(y)) - img.position.top_left.y,
                );
            },
            .Text => unreachable,
        };
    }
};

pub const GUI_Layer = struct {
    elements: std.ArrayList(GUI_Element),

    pub fn init() GUI_Layer {
        return GUI_Layer{ .elements = std.ArrayList(GUI_Element).init(allocator) };
    }

    pub fn deinit(self: *const GUI_Layer) void {
        self.elements.deinit();
    }

    pub fn add_gui(self: *GUI_Layer, element: GUI_Element) !void {
        try self.elements.append(element);
    }
};
