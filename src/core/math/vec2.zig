pub fn Vec2(comptime T: type) type {
    return packed struct {
        x: T,
        y: T,

        const Self = @This();

        pub fn empty() Self {
            return Self{ .x = 0, .y = 0 };
        }

        pub fn diagonal(value: T) Self {
            return Self{ .x = value, .y = value };
        }

        pub fn init(x: T, y: T) Self {
            return Self{ .x = x, .y = y };
        }

        pub fn multiply(self: Self, scalar: T) Self {
            return Self{
                .x = self.x * scalar,
                .y = self.y * scalar,
            };
        }

        pub fn add(self: Self, other: Self) Self {
            return Self{
                .x = self.x + other.x,
                .y = self.y + other.y,
            };
        }
    };
}

pub const Vec2f32 = Vec2(f32);
pub const Vec2i32 = Vec2(i32);
