const Vec3 = @import("../math_3d/vector.zig").Vec3;

const Self = @This();

orig: Vec3,
dir: Vec3,

pub fn init(origin: Vec3, direction: Vec3) Self {
    return Self{ .orig = origin, .dir = direction };
}

// represents ray => P(t) = A + dt
pub fn at(self: Self, t: f32) Vec3 {
    return self.orig.add(self.dir.scale(t));
}
