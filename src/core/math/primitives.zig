pub const Vec3 = @import("vec3.zig").Vec3;
pub const Vec4 = @import("vec4.zig").Vec4;
pub const Quaternion = @import("quaternion.zig").Quaternion;
pub const Matrix4 = @import("matrix4.zig").Matrix4;

pub const Vec2i = struct { x: i32, y: i32 };
pub const Vec2 = struct { x: f32, y: f32 };

pub const Color3 = struct { r: u8, g: u8, b: u8 };
pub const Color4 = struct { r: u8, g: u8, b: u8, a: u8 };

pub const BLACK = Color4{ .r = 0, .g = 0, .b = 0, .a = 100 };
pub const WHITE = Color4{ .r = 255, .g = 255, .b = 255, .a = 100 };
pub const RED = Color4{ .r = 255, .g = 0, .b = 0, .a = 100 };
