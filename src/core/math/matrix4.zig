pub const ProjectionMatrixOptions = struct {
    near_plane: f32,
    far_plane: f32,
    right: f32,
    left: f32,
    top: f32,
    bottom: f32,
};

pub const Matrix4 = struct {
    m: [4][4]f32,

    pub fn empty() Matrix4 {
        return Matrix4{ .m = [4][4]f32{
            [4]f32{ 0.0, 0.0, 0.0, 0.0 },
            [4]f32{ 0.0, 0.0, 0.0, 0.0 },
            [4]f32{ 0.0, 0.0, 0.0, 0.0 },
            [4]f32{ 0.0, 0.0, 0.0, 0.0 },
        } };
    }

    /// Projection Matrix is of the form:
    /// [
    ///     [ 2n/r-l 0 (r+l)/r-l 0 ]
    ///     [ 0 2n/t-b (t+b)/t-b 0 ]
    ///     [ 0 0 (n+f)/n-f 2nf/n-f ]
    ///     [ 0 0 -1 0 ]
    /// ]
    ///
    /// Learn more:
    /// https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/building-basic-perspective-projection-matrix.html
    /// https://www.scratchapixel.com/lessons/3d-basic-rendering/perspective-and-orthographic-projection-matrix/opengl-perspective-projection-matrix.html
    pub fn projection_matrix(options: ProjectionMatrixOptions) Matrix4 {
        return Matrix4{ .m = [4][4]f32{
            [4]f32{
                (2 * options.near_plane) / (options.right - options.left),
                0.0,
                (options.right + options.left) / (options.right - options.left),
                0.0,
            },
            [4]f32{
                0.0,
                (2 * options.near_plane) / (options.top - options.bottom),
                (options.top + options.bottom) / (options.top - options.bottom),
                0.0,
            },
            [4]f32{
                0.0,
                0.0,
                (options.near_plane + options.far_plane) / (options.near_plane - options.far_plane),
                (2 * options.near_plane * options.far_plane) / (options.near_plane - options.far_plane),
            },
            [4]f32{
                0.0,
                0.0,
                -1.0,
                0.0,
            },
        } };
    }
};
