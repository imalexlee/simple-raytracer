const Vec3 = @import("../math_3d/vector.zig").Vec3;
const Ray = @import("ray.zig");
const Interval = @import("interval.zig");
const HitRecord = @import("hit_record.zig");

const Self = @This();

center: Vec3,
radius: f32,

pub fn init(center: Vec3, radius: f32) Self {
    return Self{
        .center = center,
        .radius = radius,
    };
}

pub fn hit(self: Self, ray: Ray, ray_t: Interval, hit_record: *HitRecord) bool {
    const oc = ray.orig.sub(self.center);
    // vector dotted with itself is equal to its length squared
    const a = ray.dir.dot(ray.dir);
    const half_b = ray.dir.dot(oc);
    const c = oc.dot(oc) - self.radius * self.radius;

    const discriminant = half_b * half_b - a * c;
    if (discriminant < 0.0) return false;

    const sqrt_d = @sqrt(discriminant);

    var root: f32 = (-half_b - sqrt_d) / a;

    if (!ray_t.surrounds(root)) {
        root = (-half_b + sqrt_d) / a;
        if (!ray_t.surrounds(root)) {
            return false;
        }
    }

    hit_record.t = root;
    hit_record.point = ray.at(hit_record.t);
    const outward_normal = (hit_record.point.sub(self.center)).scale(1 / self.radius);
    hit_record.setFaceNormal(ray, outward_normal);

    return true;
}
