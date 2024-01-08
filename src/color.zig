const std = @import("std");
const math_3d = @import("math_3d/vector.zig");
const Ray = @import("ray.zig");

const Vec3 = math_3d.Vector(3);

pub fn writeColor(color: Vec3, writer: std.fs.File.Writer) !void {
    var temp_buf: [3]u8 = undefined;
    temp_buf[0] = @intFromFloat(255.0 * @max(0.0, @min(1.0, color.values[0])));
    temp_buf[1] = @intFromFloat(255.0 * @max(0.0, @min(1.0, color.values[1])));
    temp_buf[2] = @intFromFloat(255.0 * @max(0.0, @min(1.0, color.values[2])));

    try writer.writeAll(temp_buf[0..3]);
}
