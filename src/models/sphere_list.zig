const std = @import("std");
const Sphere = @import("sphere.zig");
const Ray = @import("ray.zig");
const Interval = @import("interval.zig");
const HitRecord = @import("hit_record.zig");

const Self = @This();
spheres: std.ArrayList(Sphere),

pub fn init(allocator: std.mem.Allocator) Self {
    return Self{
        .spheres = std.ArrayList(Sphere).init(allocator),
    };
}

pub fn hit(self: Self, ray: Ray, ray_t: Interval, hit_record: *HitRecord) bool {
    var hit_found = false;
    var closest_t = ray_t.max;
    var temp_hit_record: HitRecord = undefined;

    for (self.spheres.items) |sphere| {
        if (sphere.hit(ray, Interval.init(ray_t.min, closest_t), &temp_hit_record)) {
            hit_found = true;
            closest_t = temp_hit_record.t;
            hit_record.* = temp_hit_record;
        }
    }

    return hit_found;
}
