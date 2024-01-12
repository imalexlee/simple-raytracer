const std = @import("std");

const Self = @This();

min: f32,
max: f32,

pub fn init(min: f32, max: f32) Self {
    return Self{ .min = min, .max = max };
}

pub fn empty() Self {
    return Self{
        .min = std.math.inf(f32),
        .max = -std.math.inf(f32),
    };
}

pub fn universe() Self {
    return Self{
        .min = -std.math.inf(f32),
        .max = std.math.inf(f32),
    };
}

pub fn contains(self: Self, x: f32) bool {
    return x >= self.min and x <= self.max;
}

pub fn surrounds(self: Self, x: f32) bool {
    return x > self.min and x < self.max;
}

pub fn clamp(self: Self, x: f32) f32 {
    if (x < self.min) return self.min;
    if (x > self.max) return self.max;
    return x;
}
