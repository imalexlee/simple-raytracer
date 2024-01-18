const std = @import("std");
const color_utils = @import("../color.zig");

const Ray = @import("ray.zig");
const Vec3 = @import("../math_3d/vector.zig").Vec3;
const HitRecord = @import("hit_record.zig");
const Interval = @import("interval.zig");
const SphereList = @import("sphere_list.zig");

const Self = @This();

allocator: std.mem.Allocator,

image_width: u32 = 1,
image_height: u32 = 1,
aspect_ratio: f32 = 1.0,
samples_per_pixel: u32 = 10,
max_depth: u32 = 30,

look_from: Vec3,
look_at: Vec3,
v_up: Vec3,
u: Vec3 = undefined,
v: Vec3 = undefined,
w: Vec3 = undefined,

vfov: f32 = 90,

defocus_angle: f32 = undefined,
focus_dist: f32 = undefined,
defocus_disk_u: Vec3 = undefined,
defocus_disk_v: Vec3 = undefined,

center: Vec3 = undefined,
pixel_delta_u: Vec3 = undefined,
pixel_delta_v: Vec3 = undefined,
pixel00_loc: Vec3 = undefined,

pub fn render(self: Self, world: SphereList, file: std.fs.File) !void {
    const header = try std.fmt.allocPrint(self.allocator, "P6\n{} {}\n255\n", .{ self.image_width, self.image_height });

    const file_writer = file.writer();
    _ = try file_writer.write(header);

    for (0..self.image_height) |j| {
        for (0..self.image_width) |i| {
            var color = Vec3.init(.{ 0.0, 0.0, 0.0 });

            for (0..self.samples_per_pixel) |_| {
                const ray = getRay(self, @intCast(i), @intCast(j));
                color = color.add(rayColor(ray, self.max_depth, world));
            }

            try color_utils.writeColor(color, self.samples_per_pixel, file_writer);
        }
    }
}

pub fn init(allocator: std.mem.Allocator, image_width: u32, aspect_ratio: f32, samples_per_pixel: ?u32, vfov: f32) Self {
    var Camera = Self{
        .image_width = image_width,
        .allocator = allocator,
        .aspect_ratio = aspect_ratio,
        .samples_per_pixel = samples_per_pixel orelse 10,
        .vfov = vfov,
        .look_from = Vec3.init(.{ 13.0, 2.0, 3.0 }),
        .look_at = Vec3.init(.{ 0.0, 0.0, 0.0 }),
        .v_up = Vec3.init(.{ 0.0, 1.0, 0.0 }),
        .defocus_angle = 0.6,
    };

    //Camera.focus_dist = Camera.look_at.sub(Camera.look_from).length();
    Camera.focus_dist = 10.0;

    Camera.center = Camera.look_from;

    Camera.w = (Camera.look_from.sub(Camera.look_at)).normalize();
    Camera.u = (Camera.v_up.cross(Camera.w)).normalize();
    Camera.v = Camera.w.cross(Camera.u);

    const width_f = @as(f32, @floatFromInt(image_width));
    Camera.image_height = @intFromFloat(@max(1.0, width_f / Camera.aspect_ratio));
    const height_f = @as(f32, @floatFromInt(Camera.image_height));

    //const camera_center = Vec3{ .values = .{ 0.0, 0.0, 0.0 } };
    //const focal_length: f32 = (Camera.look_from.sub(Camera.look_at)).length();

    const theta = std.math.degreesToRadians(f32, Camera.vfov);
    const h = @tan(theta / 2.0);
    const viewport_height: f32 = 2 * h * Camera.focus_dist;
    const viewport_width: f32 = viewport_height * (width_f / height_f);

    const viewport_u = Camera.u.scale(viewport_width);
    const viewport_v = Camera.v.scale(-viewport_height);

    Camera.pixel_delta_u = viewport_u.scale(@as(f32, 1.0) / width_f);
    Camera.pixel_delta_v = viewport_v.scale(@as(f32, 1.0) / height_f);

    const viewport_upper_left =
        Camera.center
        .sub(Camera.w.scale(Camera.focus_dist))
        .sub(viewport_u.scale(0.5))
        .sub(viewport_v.scale(0.5));

    const defocus_radius = Camera.focus_dist * @tan(std.math.degreesToRadians(f32, Camera.defocus_angle));
    Camera.defocus_disk_u = Camera.u.scale(defocus_radius);
    Camera.defocus_disk_v = Camera.v.scale(defocus_radius);

    const pixel_offset = Camera.pixel_delta_u.add(Camera.pixel_delta_v);
    Camera.pixel00_loc = viewport_upper_left.add(pixel_offset.scale(0.5));

    return Camera;
}

fn getRay(self: Self, x: u32, y: u32) Ray {
    const pixel_x = self.pixel_delta_u.scale(@floatFromInt(x));
    const pixel_y = self.pixel_delta_v.scale(@floatFromInt(y));
    const pixel_center = self.pixel00_loc.add(pixel_x.add(pixel_y));
    const pixel_sample = pixel_center.add(getRandomSamplePoint(self));
    const ray_origin = if (self.defocus_angle <= 0) self.center else defocusDiskSample(self);
    const ray_direction = pixel_sample.sub(ray_origin);

    return Ray.init(ray_origin, ray_direction);
}

fn defocusDiskSample(self: Self) Vec3 {
    const p = Vec3.randomInUnitDisk() catch {};
    const new_x = self.defocus_disk_u.scale(p.values[0]);
    const new_y = self.defocus_disk_v.scale(p.values[1]);
    return self.center.add(new_x).add(new_y);
}

fn getRandomSamplePoint(self: Self) Vec3 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        // Ignoring possible error for code simplicity
        std.os.getrandom(std.mem.asBytes(&seed)) catch {};
        break :blk seed;
    });
    const rand = prng.random();

    const px = -0.5 * rand.float(f32);
    const py = -0.5 * rand.float(f32);
    const vec_x = self.pixel_delta_u.scale(px);
    const vec_y = self.pixel_delta_v.scale(py);
    return vec_x.add(vec_y);
}

fn rayColor(ray: Ray, depth: u32, world: SphereList) Vec3 {
    var hit_record: HitRecord = undefined;

    if (depth == 0) return Vec3.init(.{ 0.0, 0.0, 0.0 });

    if (world.hit(ray, Interval.init(0.001, std.math.inf(f32)), &hit_record)) {
        var scattered: Ray = undefined;
        var attenuation: Vec3 = undefined;
        //std.debug.print("hit record material: {any}\n", .{hit_record.mat.type});
        if (hit_record.mat.*.scatter(&ray, &hit_record, &attenuation, &scattered)) {
            const new_depth = depth -| 1;
            //            std.debug.print("attentuation = {any}\n", .{attenuation.values});
            return attenuation.mult(rayColor(scattered, new_depth, world));
        }
        return Vec3.init(.{ 0.0, 0.0, 0.0 });
    }

    const unit_direction = ray.dir.normalize();
    const a: f32 = 0.5 * (unit_direction.values[1] + 1.0);
    const start = Vec3.init(.{ 1.0, 1.0, 1.0 }).scale(1.0 - a);
    const end = Vec3.init(.{ 0.5, 0.7, 1.0 }).scale(a);
    return start.add(end);
}
