const std = @import("std");
const math_3d = @import("math_3d/vector.zig");

const Vec3 = math_3d.Vector(3);

pub const Sphere = struct {
    const Self = @This();

    center: Vec3,
    radius: f32,

    pub fn init(center: Vec3, radius: f32) Self {
        return Self{
            .center = center,
            .radius = radius,
        };
    }
};
