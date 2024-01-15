const std = @import("std");

/// returns random f32 [0,1)
pub fn random() !f32 {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        // Ignoring possible error for code simplicity
        std.os.getrandom(std.mem.asBytes(&seed)) catch {};
        break :blk seed;
    });
    const rand = prng.random();
    return rand.float(f32);
}

pub fn randomInRange(min: f32, max: f32) !f32 {
    return min + (max - min) * try random();
}
