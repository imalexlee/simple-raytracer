const std = @import("std");
const math_3d = @import("math_3d/vector.zig");
const color_utils = @import("color.zig");
const Ray = @import("ray.zig");

const Vec3 = math_3d.Vector(3);

const ASPECT_RATIO: f32 = 16.0 / 9.0;
const WIDTH = 400;

pub fn hitSphere(center: Vec3, radius: f32, ray: Ray) f32 {
    const oc = ray.orig.sub(center);
    const a = ray.dir.dot(ray.dir);
    const b = 2.0 * (ray.dir.dot(oc));
    const c = oc.dot(oc) - radius * radius;

    const discriminant = b * b - 4 * a * c;
    if (discriminant < 0) {
        return -1.0;
    } else {
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}

pub fn rayColor(ray: Ray) Vec3 {
    const center = Vec3.init(.{ 0.0, 0.0, -1.0 });
    const t = hitSphere(center, 0.5, ray);
    if (t > 0.0) {
        // normal vector of the point on the sphere
        const n = ray.at(t).sub(center).normalize();
        return Vec3.init(.{ n.values[0] + 1.0, n.values[1] + 1.0, n.values[2] + 1.0 }).scale(0.5);
    }
    const unit_direction = ray.dir.normalize();
    // lerp!
    const a: f32 = 0.5 * (unit_direction.values[1] + 1.0);
    const start = Vec3.init(.{ 1.0, 1.0, 1.0 }).scale(1.0 - a);
    const end = Vec3.init(.{ 0.5, 0.7, 1.0 }).scale(a);
    return start.add(end);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    var allocator = arena.allocator();
    defer arena.deinit();

    const width_f = @as(f32, @floatFromInt(WIDTH));
    const file = try std.fs.cwd().createFile("out.ppm", .{});
    defer file.close();

    const image_height: u32 = @intFromFloat(@max(1.0, width_f / ASPECT_RATIO));

    const viewport_height: f32 = 2.0;
    const viewport_width: f32 = viewport_height * (width_f / image_height);
    const camera_center = Vec3{ .values = .{ 0.0, 0.0, 0.0 } };
    const focal_length: f32 = 1.0;

    const viewport_u = Vec3.init(.{ viewport_width, 0.0, 0.0 });
    const viewport_v = Vec3.init(.{ 0.0, -viewport_height, 0.0 });

    const pixel_delta_u = viewport_u.scale(@as(f32, 1.0) / width_f);
    const pixel_delta_v = viewport_v.scale(@as(f32, 1.0) / image_height);

    const viewport_upper_left =
        camera_center
        .sub(Vec3.init(.{ 0.0, 0.0, focal_length }))
        .sub(viewport_u.scale(0.5))
        .sub(viewport_v.scale(0.5));

    const pixel_offset = pixel_delta_u.add(pixel_delta_v);
    const pixel00_loc = viewport_upper_left.add(pixel_offset.scale(0.5));

    const header = try std.fmt.allocPrint(allocator, "P6\n{} {}\n255\n", .{ WIDTH, image_height });
    defer allocator.free(header);

    const file_writer = file.writer();
    _ = try file_writer.write(header);

    for (0..image_height) |j| {
        for (0..WIDTH) |i| {
            // loc + delat_u * i + delta_v * j
            const pixel_x = pixel_delta_u.scale(@floatFromInt(i));
            const pixel_y = pixel_delta_v.scale(@floatFromInt(j));
            const pixel_center = pixel00_loc.add(pixel_x.add(pixel_y));
            const ray_direction = pixel_center.sub(camera_center);

            const ray = Ray.init(camera_center, ray_direction);
            const color = rayColor(ray);

            try color_utils.writeColor(color, file_writer);
        }
    }
}
