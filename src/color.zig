const std = @import("std");
const math_3d = @import("math_3d/vector.zig");
const assert = std.debug.assert;

const Vec3 = math_3d.Vector(3);

pub fn writeColor(color: Vec3, samples_per_pixel: u32, writer: std.fs.File.Writer) !void {
    const samples_f: f32 = @floatFromInt(samples_per_pixel);
    // sqrt transforms values from linear to gamma space
    const r: f32 = @sqrt(color.values[0] / samples_f);
    const g: f32 = @sqrt(color.values[1] / samples_f);
    const b: f32 = @sqrt(color.values[2] / samples_f);

    // std.debug.print("{d:.3} {d:.3} {d:.3}\n", .{ r, g, b });

    var temp_buf: [3]u8 = undefined;
    temp_buf[0] = @intFromFloat(255.0 * @max(0.0, @min(1.0, r)));
    temp_buf[1] = @intFromFloat(255.0 * @max(0.0, @min(1.0, g)));
    temp_buf[2] = @intFromFloat(255.0 * @max(0.0, @min(1.0, b)));

    try writer.writeAll(temp_buf[0..3]);
}
