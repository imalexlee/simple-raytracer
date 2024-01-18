const std = @import("std");
const Vec3 = @import("math_3d/vector.zig").Vec3;
const SphereList = @import("models/sphere_list.zig");
const Sphere = @import("models/sphere.zig");
const Camera = @import("models/camera.zig");
const Material = @import("models/materials.zig");
const math_utils = @import("math_3d/utils.zig");

pub fn main() !void {
    const start = std.time.milliTimestamp();
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    const allocator = arena.allocator();
    defer arena.deinit();

    //    var materials_list = try std.ArrayList(Material).initCapacity(allocator, 441);

    const aspect_ratio = 16.0 / 9.0;
    const image_width = 2560;

    var world = SphereList.init(allocator);

    var ground_material = Material.initLambertion(Vec3.init(.{ 0.5, 0.5, 0.5 }));
    // ground
    try world.spheres.append(Sphere.init(Vec3.init(.{ 0.0, -1000, 0.0 }), 1000.0, &ground_material));
    var i: i32 = -11;

    while (i < 11) : (i += 1) {
        var j: i32 = -11;
        while (j < 11) : (j += 1) {
            const mat_choice = try math_utils.random();
            const x = @as(f32, @floatFromInt(i)) + 0.9 * try math_utils.random();
            //            std.debug.print("x: {}\n", .{x});
            const y = @as(f32, @floatFromInt(j)) + 0.9 * try math_utils.random();
            //           std.debug.print("y: {}\n", .{y});
            const center = Vec3.init(.{ x, 0.2, y });

            if ((center.sub(Vec3.init(.{ 4.0, 0.2, 0.0 }))).length() > @as(f32, 0.9)) {
                if (mat_choice < 0.3) {
                    // matte
                    const color = try Vec3.randomInRange(0.0, 1.0);
                    //try materials_list.append(mat;
                    const material = try allocator.create(Material);
                    material.* = Material.initLambertion(color);
                    try world.spheres.append(Sphere.init(center, 0.2, material));
                } else if (mat_choice < 0.7) {
                    // glass
                    const material = try allocator.create(Material);
                    material.* = Material.initDielectric(1.5);
                    //try materials_list.append(material);
                    try world.spheres.append(Sphere.init(center, 0.2, material));
                } else {
                    // metal
                    const color = try Vec3.randomInRange(0.0, 1.0);
                    //                std.debug.print("color: {any}\n", .{color});
                    const material = try allocator.create(Material);
                    material.* = Material.initMetal(color);
                    // try materials_list.append(material);
                    try world.spheres.append(Sphere.init(center, 0.2, material));
                }
            }
        }
    }

    var dielectric = Material.initDielectric(1.5);
    try world.spheres.append(Sphere.init(Vec3.init(.{ 0.0, 1.0, 0.0 }), 1.0, &dielectric));

    var lambertian = Material.initLambertion(Vec3.init(.{ 0.4, 0.2, 0.1 }));
    try world.spheres.append(Sphere.init(Vec3.init(.{ -4.0, 1.0, 0.0 }), 1.0, &lambertian));

    var metal = Material.initMetal(Vec3.init(.{ 0.7, 0.6, 0.5 }));
    try world.spheres.append(Sphere.init(Vec3.init(.{ 4.0, 1.0, 0.0 }), 1.0, &metal));

    const camera = Camera.init(allocator, image_width, aspect_ratio, 500, 20);
    const file = try std.fs.cwd().createFile("out.ppm", .{});
    defer file.close();

    try camera.render(world, file);
    const total_time = std.time.milliTimestamp() - start;
    std.debug.print("time: {}\n", .{total_time});
}
