const std = @import("std");
const utils = @import("utils.zig");

// ready made types
pub const Vec2 = Vector(2);
pub const Vec3 = Vector(3);
pub const Vec4 = Vector(4);

pub fn Vector(comptime N: usize) type {
    return struct {
        const Self = @This();

        values: [N]f32,

        pub fn init(values: [N]f32) Self {
            return .{ .values = values };
        }

        pub fn normalize(self: Self) Self {
            var mag: f32 = 0.0;
            var normalized_vec: Self = undefined;
            for (self.values) |value| {
                mag += std.math.pow(f32, value, 2.0);
            }
            mag = @sqrt(mag);

            for (0..self.values.len) |i| {
                normalized_vec.values[i] = self.values[i] / mag;
            }
            return normalized_vec;
        }

        pub fn dot(self: Self, other: Self) f32 {
            var product: f32 = 0;
            for (0..self.values.len) |i| {
                product += self.values[i] * other.values[i];
            }
            return product;
        }

        pub fn sub(self: Self, other: Self) Self {
            const left: @Vector(N, f32) = self.values;
            const right: @Vector(N, f32) = other.values;

            return Self{ .values = left - right };
        }

        pub fn add(self: Self, other: Self) Self {
            const left: @Vector(N, f32) = self.values;
            const right: @Vector(N, f32) = other.values;

            return Self{ .values = left + right };
        }

        pub fn scale(self: Self, factor: f32) Self {
            return Self{ .values = .{
                self.values[0] * factor,
                self.values[1] * factor,
                self.values[2] * factor,
            } };
        }

        pub fn length(self: Self) f32 {
            var vals_squared: f32 = 0.0;
            for (self.values) |value| {
                vals_squared += (value * value);
            }
            return @sqrt(vals_squared);
        }

        pub fn cross(self: Self, other: Self) Self {
            if (N != 3) {
                @compileError("A cross product can only be calculated for a 3D vector.");
            }
            return Self{
                .values = [3]f32{
                    self.values[1] * other.values[2] - self.values[2] * other.values[1],
                    self.values[2] * other.values[0] - self.values[0] * other.values[2],
                    self.values[0] * other.values[1] - self.values[1] * other.values[0],
                },
            };
        }

        fn randomInRange(min: f32, max: f32) !Self {
            var values: [N]f32 = undefined;

            for (0..values.len) |i| {
                values[i] = try utils.randomInRange(min, max);
            }

            return Self.init(values);
        }

        fn randomInUnitSphere() !Self {
            while (true) {
                const vec = try randomInRange(-1.0, 1.0);
                if (vec.length() < 1) return vec;
            }
        }

        pub fn randomUnitVector() !Self {
            const vec = try randomInUnitSphere();
            return vec.normalize();
        }

        pub fn randomOnHemisphere(normal: Vec3) !Self {
            const vec = try randomUnitVector();
            // were going in the right direction
            if (vec.dot(normal) > 0.0) {
                return vec;
            } else {
                return vec.scale(-1.0);
            }
        }
    };
}
