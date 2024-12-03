const appropriate_division = @import("utils.zig").appropriate_division;

pub fn Mat4(comptime T: type) type {
    return struct {
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

        pub fn from(m: [4][4]T) Self {
            return Self{ .m = m };
        }

        /// Returns the ith row of the matrix, caller ensures 0 <= i <= 4
        pub fn ith(self: Self, i: usize) [4]T {
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

        pub fn inverse(self: Self) Self {
            var res: [4][4]T = undefined;
            const m = self.m;

            res[0][0] = m[1][1] * m[2][2] * m[3][3] -
                m[1][1] * m[2][3] * m[3][2] -
                m[2][1] * m[1][2] * m[3][3] +
                m[2][1] * m[1][3] * m[3][2] +
                m[3][1] * m[1][2] * m[2][3] -
                m[3][1] * m[1][3] * m[2][2];

            res[1][0] = -m[1][0] * m[2][2] * m[3][3] +
                m[1][0] * m[2][3] * m[3][2] +
                m[2][0] * m[1][2] * m[3][3] -
                m[2][0] * m[1][3] * m[3][2] -
                m[3][0] * m[1][2] * m[2][3] +
                m[3][0] * m[1][3] * m[2][2];

            res[2][0] = m[1][0] * m[2][1] * m[3][3] -
                m[1][0] * m[2][3] * m[3][1] -
                m[2][0] * m[1][1] * m[3][3] +
                m[2][0] * m[1][3] * m[3][1] +
                m[3][0] * m[1][1] * m[2][3] -
                m[3][0] * m[1][3] * m[2][1];

            res[3][0] = -m[1][0] * m[2][1] * m[3][2] +
                m[1][0] * m[2][2] * m[3][1] +
                m[2][0] * m[1][1] * m[3][2] -
                m[2][0] * m[1][2] * m[3][1] -
                m[3][0] * m[1][1] * m[2][2] +
                m[3][0] * m[1][2] * m[2][1];

            res[0][1] = -m[0][1] * m[2][2] * m[3][3] +
                m[0][1] * m[2][3] * m[3][2] +
                m[2][1] * m[0][2] * m[3][3] -
                m[2][1] * m[0][3] * m[3][2] -
                m[3][1] * m[0][2] * m[2][3] +
                m[3][1] * m[0][3] * m[2][2];

            res[1][1] = m[0][0] * m[2][2] * m[3][3] -
                m[0][0] * m[2][3] * m[3][2] -
                m[2][0] * m[0][2] * m[3][3] +
                m[2][0] * m[0][3] * m[3][2] +
                m[3][0] * m[0][2] * m[2][3] -
                m[3][0] * m[0][3] * m[2][2];

            res[2][1] = -m[0][0] * m[2][1] * m[3][3] +
                m[0][0] * m[2][3] * m[3][1] +
                m[2][0] * m[0][1] * m[3][3] -
                m[2][0] * m[0][3] * m[3][1] -
                m[3][0] * m[0][1] * m[2][3] +
                m[3][0] * m[0][3] * m[2][1];

            res[3][1] = m[0][0] * m[2][1] * m[3][2] -
                m[0][0] * m[2][2] * m[3][1] -
                m[2][0] * m[0][1] * m[3][2] +
                m[2][0] * m[0][2] * m[3][1] +
                m[3][0] * m[0][1] * m[2][2] -
                m[3][0] * m[0][2] * m[2][1];

            res[0][2] = m[0][1] * m[1][2] * m[3][3] -
                m[0][1] * m[1][3] * m[3][2] -
                m[1][1] * m[0][2] * m[3][3] +
                m[1][1] * m[0][3] * m[3][2] +
                m[3][1] * m[0][2] * m[1][3] -
                m[3][1] * m[0][3] * m[1][2];

            res[1][2] = -m[0][0] * m[1][2] * m[3][3] +
                m[0][0] * m[1][3] * m[3][2] +
                m[1][0] * m[0][2] * m[3][3] -
                m[1][0] * m[0][3] * m[3][2] -
                m[3][0] * m[0][2] * m[1][3] +
                m[3][0] * m[0][3] * m[1][2];

            res[2][2] = m[0][0] * m[1][1] * m[3][3] -
                m[0][0] * m[1][3] * m[3][1] -
                m[1][0] * m[0][1] * m[3][3] +
                m[1][0] * m[0][3] * m[3][1] +
                m[3][0] * m[0][1] * m[1][3] -
                m[3][0] * m[0][3] * m[1][1];

            res[3][2] = -m[0][0] * m[1][1] * m[3][2] +
                m[0][0] * m[1][2] * m[3][1] +
                m[1][0] * m[0][1] * m[3][2] -
                m[1][0] * m[0][2] * m[3][1] -
                m[3][0] * m[0][1] * m[1][2] +
                m[3][0] * m[0][2] * m[1][1];

            res[0][3] = -m[0][1] * m[1][2] * m[2][3] +
                m[0][1] * m[1][3] * m[2][2] +
                m[1][1] * m[0][2] * m[2][3] -
                m[1][1] * m[0][3] * m[2][2] -
                m[2][1] * m[0][2] * m[1][3] +
                m[2][1] * m[0][3] * m[1][2];

            res[1][3] = m[0][0] * m[1][2] * m[2][3] -
                m[0][0] * m[1][3] * m[2][2] -
                m[1][0] * m[0][2] * m[2][3] +
                m[1][0] * m[0][3] * m[2][2] +
                m[2][0] * m[0][2] * m[1][3] -
                m[2][0] * m[0][3] * m[1][2];

            res[2][3] = -m[0][0] * m[1][1] * m[2][3] +
                m[0][0] * m[1][3] * m[2][1] +
                m[1][0] * m[0][1] * m[2][3] -
                m[1][0] * m[0][3] * m[2][1] -
                m[2][0] * m[0][1] * m[1][3] +
                m[2][0] * m[0][3] * m[1][1];

            res[3][3] = m[0][0] * m[1][1] * m[2][2] -
                m[0][0] * m[1][2] * m[2][1] -
                m[1][0] * m[0][1] * m[2][2] +
                m[1][0] * m[0][2] * m[2][1] +
                m[2][0] * m[0][1] * m[1][2] -
                m[2][0] * m[0][2] * m[1][1];

            const det = m[0][0] * res[0][0] + m[0][1] * res[1][0] + m[0][2] * res[2][0] + m[0][3] * res[3][0];
            if (det == 0) return Self{ .m = res };

            for (0..4) |i| {
                for (0..4) |j| {
                    res[i][j] = res[i][j] / det;
                }
            }

            return Self{ .m = res };
        }
    };
}

pub const Mat4f32 = Mat4(f32);
