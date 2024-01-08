pub fn Matrix(comptime N: usize) type {
    return struct {
        const Self = @This();

        values: [N][N]f32,

        pub const IDENTITY: Self = blk: {
            var result: Self = undefined;

            comptime var i = 0;
            while (i < N) : (i += 1) {
                comptime var j = 0;
                while (j < N) : (j += 1) {
                    result.values[i][j] = if (i == j) 1 else 0;
                }
            }
            break :blk result;
        };

        pub fn init(values: [N][N]f32) Self {
            return .{ .values = values };
        }
    };
}
