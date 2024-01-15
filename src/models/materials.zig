const std = @import("std");
const Ray = @import("ray.zig");
const HitRecord = @import("hit_record.zig");
const Vec3 = @import("../math_3d/vector.zig").Vec3;
const VecUtils = @import("../math_3d/utils.zig");

const Self = @This();

const MaterialTypes = enum {
    Dielectric,
    Lambertian,
    Metal,
};

type: MaterialTypes,
albedo: ?Vec3 = null,
ir: ?f32 = null,

pub fn initLambertion(color: Vec3) Self {
    return Self{
        .type = MaterialTypes.Lambertian,
        .albedo = color,
    };
}

pub fn initMetal(color: Vec3) Self {
    return Self{
        .type = MaterialTypes.Metal,
        .albedo = color,
    };
}

pub fn initDielectric(ir: f32) Self {
    return Self{
        .type = MaterialTypes.Dielectric,
        .albedo = Vec3.init(.{ 1.0, 1.0, 1.0 }),
        .ir = ir,
    };
}

pub fn scatter(self: Self, ray_in: *const Ray, hit_record: *HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    switch (self.type) {
        MaterialTypes.Lambertian => return scatterLambertian(self, ray_in, hit_record, attenuation, scattered),
        MaterialTypes.Metal => return scatterMetal(self, ray_in, hit_record, attenuation, scattered),
        MaterialTypes.Dielectric => return scatterDielectric(self, ray_in, hit_record, attenuation, scattered),
    }
}

fn scatterLambertian(self: Self, ray_in: *const Ray, hit_record: *HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    _ = ray_in;
    var scatter_direction = hit_record.normal.add(Vec3.randomUnitVector() catch {});

    if (scatter_direction.nearZero()) {
        scatter_direction = hit_record.normal;
    }
    scattered.* = Ray.init(hit_record.point, scatter_direction);
    attenuation.* = self.albedo.?;
    return true;
}

fn scatterMetal(self: Self, ray_in: *const Ray, hit_record: *HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    const reflected = (ray_in.dir.reflect(hit_record.normal)).normalize();

    scattered.* = Ray.init(hit_record.point, reflected);
    attenuation.* = self.albedo.?;
    return true;
}

fn scatterDielectric(self: Self, ray_in: *const Ray, hit_record: *HitRecord, attenuation: *Vec3, scattered: *Ray) bool {
    const refraction_ratio = if (hit_record.front_face) 1.0 / self.ir.? else self.ir.?;
    var unit_direction = ray_in.dir.normalize();
    const cos_theta = @min(1.0, unit_direction.scale(-1.0).dot(hit_record.normal));
    const sin_theta = @sqrt(1.0 - cos_theta * cos_theta);

    const can_refract = refraction_ratio * sin_theta <= 1.0;

    var direction: Vec3 = undefined;
    if (can_refract and reflectance(cos_theta, refraction_ratio) < VecUtils.random() catch {}) {
        direction = Vec3.refract(&unit_direction, &hit_record.normal, refraction_ratio);
    } else {
        // must reflect since critical angle was reached
        direction = Vec3.reflect(unit_direction, hit_record.normal);
    }

    scattered.* = Ray.init(hit_record.point, direction);
    attenuation.* = self.albedo.?;
    return true;
}

fn reflectance(cosine: f32, ref_idx: f32) f32 {
    var r0 = (1 - ref_idx) / (1 + ref_idx);
    r0 = r0 * r0;
    return r0 + (1 - r0) * std.math.pow(f32, (1 - cosine), 5);
}
