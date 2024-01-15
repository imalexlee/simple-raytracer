const std = @import("std");
const Vec3 = @import("math_3d/vector.zig").Vec3;
const SphereList = @import("models/sphere_list.zig");
const Sphere = @import("models/sphere.zig");
const Camera = @import("models/camera.zig");
const Material = @import("models/materials.zig");

pub fn main() !void {
    const start = std.time.milliTimestamp();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    defer arena.deinit();

    const aspect_ratio = 16.0 / 9.0;
    const image_width = 500;

    var lambertian = Material.initLambertion(Vec3.init(.{ 0.5, 0.8, 0.6 }));
    var metal = Material.initMetal(Vec3.init(.{ 0.7, 0.7, 0.7 }));
    var dielectric = Material.initDielectric(1.5);

    var world = SphereList.init(allocator);
    // middle
    try world.spheres.append(Sphere.init(
        Vec3.init(.{ 0.0, 0.0, -1.0 }),
        -0.2,
        &dielectric,
    ));
    // right
    try world.spheres.append(Sphere.init(
        Vec3.init(.{ 1.0, 0.0, -1.5 }),
        0.5,
        &metal,
    ));
    // left
    try world.spheres.append(Sphere.init(
        Vec3.init(.{ -1.0, 0.0, -1.6 }),
        0.5,
        &metal,
    ));

    // ground
    try world.spheres.append(Sphere.init(
        Vec3.init(.{ 0.0, -100.5, -1.0 }),
        100.0,
        &lambertian,
    ));

    const camera = Camera.init(allocator, image_width, aspect_ratio, 50, 90);
    const file = try std.fs.cwd().createFile("out.ppm", .{});
    defer file.close();

    try camera.render(world, file);
    const total_time = std.time.milliTimestamp() - start;
    std.debug.print("time: {}\n", .{total_time});
}
