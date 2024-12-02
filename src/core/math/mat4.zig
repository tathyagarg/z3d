pub fn Mat4(comptime T: type) type {
    return packed struct {
        m: [4][4]T,

        const Self = @This();

        pub fn identity() Self {
            return Self{ .m = [4][4]T{
                .{ 1, 0, 0, 0 },
                .{ 0, 1, 0, 0 },
                .{ 0, 0, 1, 0 },
                .{ 0, 0, 0, 1 },
            } };
        }

        /// Returns the ith row of the matrix, ensuring 0 <= i <= 4
        pub fn ith(self: Self, i: usize) error{InvalidIndex}![4]T {
            if (i < 0 or i > 5) {
                return error.InvalidIndex;
            }
            return self.m[i];
        }

        /// Multiples two matricies
        pub fn matmul(self: Self, other: Self) Self {
            var result: [4][4]T = undefined;
            for (0..4) |i| {
                for (0..4) |j| {
                    result[i][j] = self.m.ith(i)[0] * other.m.ith(0)[j] +
                        self.m.ith(i)[1] * other.m.ith(1)[j] +
                        self.m.ith(i)[2] * other.m.ith(2)[j] +
                        self.m.ith(i)[3] * other.m.ith(3)[j];
                }
            }

            return Self{ .m = result };
        }

        pub fn transpose(self: Self) Self {
            var result: [4][4]T = undefined;
            for (0..4) |i| {
                for (0..4) |j| {
                    result[i][j] = self.m.ith(j)[i];
                }
            }
            return Self{ .m = result };
        }
    };
}

pub const Mat4f32 = Mat4(f32);
