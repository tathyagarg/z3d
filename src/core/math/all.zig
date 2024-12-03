pub const utilslib = @import("utils.zig");
pub const appropriate_division = utilslib.appropriate_division;

// A 3 dimensional vector
// Can be used to represent direction, a point, etc.
pub const Vec3lib = @import("vec3.zig");
pub const Vec3 = Vec3lib.Vec3;
pub const Vec3i32 = Vec3lib.Vec3i32;
pub const Vec3f32 = Vec3lib.Vec3f32;

// A 4x4 matrix
pub const Mat4lib = @import("mat4.zig");
pub const Mat4 = Mat4lib.Mat4;
pub const Mat4f32 = Mat4lib.Mat4f32;

// A 2 dimensional vector
// Can be used to represent location on the screen (pixel coords)
pub const Vec2lib = @import("vec2.zig");
pub const Vec2 = Vec2lib.Vec2;
pub const Vec2f32 = Vec2lib.Vec2f32;
pub const Vec2i32 = Vec2lib.Vec2i32;
