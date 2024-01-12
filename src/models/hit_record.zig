const Vec3 = @import("../math_3d/vector.zig").Vec3;
const Ray = @import("ray.zig");

const Self = @This();

point: Vec3,
normal: Vec3,
t: f32,
front_face: bool,

// it is assumed that the outward normal is unit length here
pub fn setFaceNormal(self: *Self, ray: Ray, outward_normal: Vec3) void {
    // if ray direction and outward normal go in a similar direction,
    // the ray is on the backside or insie of the object
    self.front_face = (ray.dir.dot(outward_normal)) < 0.0;
    if (self.front_face) {
        self.normal = outward_normal;
    } else {
        self.normal = outward_normal.scale(-1.0);
    }
}
