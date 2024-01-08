const std = @import("std");
const vector = @import("vector.zig");
const matrix = @import("matrix.zig");
const math = std.math;

const Vec3 = vector.Vector(3);

const Mat4 = matrix.Matrix(4);

pub fn rotate(angle: f32, axis: Vec3) Mat4 {
    const unit = axis.normalize();

    const x = unit.values[0];
    const y = unit.values[1];
    const z = unit.values[2];

    const a = math.cos(angle) + x * x * (1 - math.cos(angle));
    const b = y * x * (1 - math.cos(angle)) + z * math.sin(angle);
    const c = z * x * (1 - math.cos(angle)) - y * math.sin(angle);

    const d = x * y * (1 - math.cos(angle)) - z * math.sin(angle);
    const e = math.cos(angle) + y * y * (1 - math.cos(angle));
    const f = z * y * (1 - math.cos(angle)) + x * math.sin(angle);

    const h = x * z * (1 - math.cos(angle)) + y * math.sin(angle);
    const i = y * z * (1 - math.cos(angle)) - x * math.sin(angle);
    const j = math.cos(angle) + z * z * (1 - math.cos(angle));

    return .{
        .values = [4][4]f32{
            .{ a, b, c, 0 },
            .{ d, e, f, 0 },
            .{ h, i, j, 0 },
            .{ 0, 0, 0, 1 },
        },
    };
}

pub fn lookAt(eye: Vec3, center: Vec3, up: Vec3) Mat4 {
    const f = center.sub(eye).normalize();
    const s = f.cross(up).normalize();
    const u = s.cross(f);

    return Mat4{
        .values = [4][4]f32{
            .{ s.values[0], u.values[0], -f.values[0], 0.0 },
            .{ s.values[1], u.values[1], -f.values[1], 0.0 },
            .{ s.values[2], u.values[2], -f.values[2], 0.0 },
            .{ -s.dot(eye), -u.dot(eye), f.dot(eye), 1.0 },
        },
    };
}

pub fn perspective(fovY: f32, aspectRatio: f32, zNear: f32, zFar: f32) Mat4 {
    const f = math.tan(fovY / 2.0);

    const a = 1.0 / (aspectRatio * f);
    const b = 1.0 / f;
    const c = -(zFar + zNear) / (zFar - zNear);
    const d = -(2.0 * zFar * zNear) / (zFar - zNear);

    return .{
        .values = [4][4]f32{
            .{ a, 0.0, 0.0, 0.0 },
            .{ 0.0, b, 0.0, 0.0 },
            .{ 0.0, 0.0, c, -1.0 },
            .{ 0.0, 0.0, d, 0.0 },
        },
    };
}
