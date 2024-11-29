pub const Vec3 = @import("vec3.zig").Vec3;
pub const Vec4 = struct { w: f32, x: f32, y: f32, z: f32 };
pub const Color3 = struct { r: u8, g: u8, b: u8 };
pub const Color4 = struct { r: u8, g: u8, b: u8, a: u8 };

pub const BLACK = Color4{ .r = 0, .g = 0, .b = 0, .a = 100 };
pub const WHITE = Color4{ .r = 255, .g = 255, .b = 255, .a = 100 };
pub const RED = Color4{ .r = 255, .g = 0, .b = 0, .a = 100 };
