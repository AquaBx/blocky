const Chunk = @import("chunk.zig").Chunk;
const Texture = @import("../texture.zig").Texture;
const utils = @import("utils.zig");
const std = @import("std");
const shader = @import("../shader.zig");
const custom_block = @import("block.zig").custom_block;
const allocator = std.heap.page_allocator;

fn workerFunction(chunk: *[]Chunk, key: usize, viewDistance: usize) !void {
    var y = key / viewDistance;
    var x = key - y * viewDistance;
    chunk.*[key] = Chunk.init(x, y);
}

pub fn check_blc(blc: custom_block) u2 {
    return if (blc.texture == 0) 0 else 1;
}

const Retour = struct {
    arraybuffer: []u32,
    indicebuffer: []u32,
};

pub const Terrain = struct {
    chunks: []Chunk,
    program: shader.program,

    const Self = @This();

    pub fn destroy(self: Self) void {
        for (self.chunks) |chunk| {
            chunk.destroy();
        }
        self.program.delete();
        allocator.free(self.chunks);
    }

    pub fn init() !Self {
        var self: Self = undefined;

        var viewDistance: usize = 8;

        self.chunks = try allocator.alloc(Chunk, viewDistance * viewDistance);
        self.program = shader.program.new();

        self.program
            .attach("./assets/shader/ligne.vert", shader.ShaderType.vertex)
            .attach("./assets/shader/ligne.frag", shader.ShaderType.fragment)
            .link();

        for (0..self.chunks.len) |key| {
            _ = try std.Thread.spawn(.{}, workerFunction, .{ &self.chunks, key, viewDistance });
        }

        return self;
    }

    pub fn optimize(self: *Self, blocks: *[65536]custom_block, chunkx: usize, chunkz: usize) Retour {
        var len: usize = 0;

        for (blocks, 0..blocks.len) |block, i| {
            if (block.texture == 0) {
                continue;
            }
            var position = utils.vecFromKey(chunkx, chunkz, i);

            var x: usize = @intFromFloat(position.x);
            var y: usize = @intFromFloat(position.y);
            var z: usize = @intFromFloat(position.z);

            if (x == 0 or z == 0 or y == 0 or y == 255) {
                continue;
            }

            if (self.getBlock(x, y, z + 1)) |blc| {
                if (blc.texture > 0) {
                    blc.hide_face(0);
                } else {
                    len += 1;
                }
            } else {
                len += 1;
            }
            if (self.getBlock(x, y, z - 1)) |blc| {
                if (blc.texture > 0) {
                    blc.hide_face(1);
                } else {
                    len += 1;
                }
            } else {
                len += 1;
            }
            if (self.getBlock(x + 1, y, z)) |blc| {
                if (blc.texture > 0) {
                    blc.hide_face(2);
                } else {
                    len += 1;
                }
            } else {
                len += 1;
            }
            if (self.getBlock(x - 1, y, z)) |blc| {
                if (blc.texture > 0) {
                    blc.hide_face(3);
                } else {
                    len += 1;
                }
            } else {
                len += 1;
            }
            if (self.getBlock(x, y + 1, z)) |blc| {
                if (blc.texture > 0) {
                    blc.hide_face(4);
                } else {
                    len += 1;
                }
            } else {
                len += 1;
            }
            if (self.getBlock(x, y - 1, z)) |blc| {
                if (blc.texture > 0) {
                    blc.hide_face(5);
                } else {
                    len += 1;
                }
            } else {
                len += 1;
            }
        }

        var arraybuffer: []u32 = allocator.alloc(u32, len * 2 * 4) catch |err| {
            std.debug.print("Trying allocate chunk : {any}\n", .{err});
            return undefined;
        };

        var indicebuffer: []u32 = allocator.alloc(u32, len * 6) catch |err| {
            std.debug.print("Trying allocate chunk : {any}\n", .{err});
            return undefined;
        };

        var j: u32 = 0;

        for (0..blocks.len) |i| {
            var position = utils.vecFromKey(chunkx, chunkz, i);

            var x: usize = @intFromFloat(position.x);
            var y: usize = @intFromFloat(position.y);
            var z: usize = @intFromFloat(position.z);

            var ux: u32 = @intFromFloat(position.x);
            var uy: u32 = @intFromFloat(position.y);
            var uz: u32 = @intFromFloat(position.z);

            if (x == 0 or z == 0 or y == 0 or y == 255) {
                continue;
            }

            var block = if (self.getBlock(x, y, z)) |val| val else continue;

            if (block.texture == 0) {
                continue;
            }

            var blc_a: u2 = if (self.getBlock(x + 1, y, z - 1)) |blc| check_blc(blc.*) else 0;
            var blc_d: u2 = if (self.getBlock(x + 1, y, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_e: u2 = if (self.getBlock(x + 1, y + 1, z)) |blc| check_blc(blc.*) else 0;
            var blc_f: u2 = if (self.getBlock(x + 1, y + 1, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_l: u2 = if (self.getBlock(x + 1, y + 1, z - 1)) |blc| check_blc(blc.*) else 0;
            var blc_m: u2 = if (self.getBlock(x + 1, y - 1, z)) |blc| check_blc(blc.*) else 0;
            var blc_n: u2 = if (self.getBlock(x + 1, y - 1, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_t: u2 = if (self.getBlock(x + 1, y - 1, z - 1)) |blc| check_blc(blc.*) else 0;

            var blc_b: u2 = if (self.getBlock(x - 1, y, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_c: u2 = if (self.getBlock(x - 1, y, z - 1)) |blc| check_blc(blc.*) else 0;
            var blc_h: u2 = if (self.getBlock(x - 1, y + 1, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_i: u2 = if (self.getBlock(x - 1, y + 1, z)) |blc| check_blc(blc.*) else 0;
            var blc_j: u2 = if (self.getBlock(x - 1, y + 1, z - 1)) |blc| check_blc(blc.*) else 0;
            var blc_p: u2 = if (self.getBlock(x - 1, y - 1, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_q: u2 = if (self.getBlock(x - 1, y - 1, z)) |blc| check_blc(blc.*) else 0;
            var blc_r: u2 = if (self.getBlock(x - 1, y - 1, z - 1)) |blc| check_blc(blc.*) else 0;

            var blc_g: u2 = if (self.getBlock(x, y + 1, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_k: u2 = if (self.getBlock(x, y + 1, z - 1)) |blc| check_blc(blc.*) else 0;
            var blc_o: u2 = if (self.getBlock(x, y - 1, z + 1)) |blc| check_blc(blc.*) else 0;
            var blc_s: u2 = if (self.getBlock(x, y - 1, z - 1)) |blc| check_blc(blc.*) else 0;

            var ptA: u32 = 4369 * (ux + 0) + 17 * (uy + 0) + (uz + 0);
            var ptB: u32 = 4369 * (ux + 1) + 17 * (uy + 0) + (uz + 0);
            var ptC: u32 = 4369 * (ux + 1) + 17 * (uy + 0) + (uz + 1);
            var ptD: u32 = 4369 * (ux + 0) + 17 * (uy + 0) + (uz + 1);
            var ptE: u32 = 4369 * (ux + 0) + 17 * (uy + 1) + (uz + 0);
            var ptF: u32 = 4369 * (ux + 1) + 17 * (uy + 1) + (uz + 0);
            var ptG: u32 = 4369 * (ux + 1) + 17 * (uy + 1) + (uz + 1);
            var ptH: u32 = 4369 * (ux + 0) + 17 * (uy + 1) + (uz + 1);

            // +x / 3 / RIGHT
            if (block.faces[3]) {
                arraybuffer[j * 8 + 0] = ptB;
                arraybuffer[j * 8 + 1] = blc_a + blc_m + blc_t;
                arraybuffer[j * 8 + 2] = ptC;
                arraybuffer[j * 8 + 3] = blc_d + blc_m + blc_n;
                arraybuffer[j * 8 + 4] = ptG;
                arraybuffer[j * 8 + 5] = blc_d + blc_e + blc_f;
                arraybuffer[j * 8 + 6] = ptF;
                arraybuffer[j * 8 + 7] = blc_a + blc_e + blc_l;

                indicebuffer[j * 6 + 0] = j * 4;
                indicebuffer[j * 6 + 1] = j * 4 + 1;
                indicebuffer[j * 6 + 2] = j * 4 + 2;
                indicebuffer[j * 6 + 3] = j * 4;
                indicebuffer[j * 6 + 4] = j * 4 + 2;
                indicebuffer[j * 6 + 5] = j * 4 + 3;

                j += 1;
            }

            // -x / 2 / LEFT OK
            if (block.faces[2]) {
                arraybuffer[j * 8 + 0] = ptD;
                arraybuffer[j * 8 + 1] = blc_b + blc_q + blc_p;
                arraybuffer[j * 8 + 2] = ptA;
                arraybuffer[j * 8 + 3] = blc_c + blc_q + blc_r;
                arraybuffer[j * 8 + 4] = ptE;
                arraybuffer[j * 8 + 5] = blc_c + blc_i + blc_j;
                arraybuffer[j * 8 + 6] = ptH;
                arraybuffer[j * 8 + 7] = blc_b + blc_i + blc_h;

                indicebuffer[j * 6 + 0] = j * 4;
                indicebuffer[j * 6 + 1] = j * 4 + 1;
                indicebuffer[j * 6 + 2] = j * 4 + 2;
                indicebuffer[j * 6 + 3] = j * 4;
                indicebuffer[j * 6 + 4] = j * 4 + 2;
                indicebuffer[j * 6 + 5] = j * 4 + 3;

                j += 1;
            }

            // +y / 5 / TOP OK
            if (block.faces[5]) {
                arraybuffer[j * 8 + 0] = ptE;
                arraybuffer[j * 8 + 1] = blc_k + blc_i + blc_j;
                arraybuffer[j * 8 + 2] = ptF;
                arraybuffer[j * 8 + 3] = blc_k + blc_e + blc_l;
                arraybuffer[j * 8 + 4] = ptG;
                arraybuffer[j * 8 + 5] = blc_g + blc_e + blc_f;
                arraybuffer[j * 8 + 6] = ptH;
                arraybuffer[j * 8 + 7] = blc_g + blc_i + blc_h;

                indicebuffer[j * 6 + 0] = j * 4;
                indicebuffer[j * 6 + 1] = j * 4 + 1;
                indicebuffer[j * 6 + 2] = j * 4 + 2;
                indicebuffer[j * 6 + 3] = j * 4;
                indicebuffer[j * 6 + 4] = j * 4 + 2;
                indicebuffer[j * 6 + 5] = j * 4 + 3;

                j += 1;
            }

            // -y / 4 / BOTTOM OK
            if (block.faces[4]) {
                arraybuffer[j * 8 + 0] = ptA;
                arraybuffer[j * 8 + 1] = blc_s + blc_q + blc_r;
                arraybuffer[j * 8 + 2] = ptB;
                arraybuffer[j * 8 + 3] = blc_s + blc_m + blc_t;
                arraybuffer[j * 8 + 4] = ptC;
                arraybuffer[j * 8 + 5] = blc_o + blc_m + blc_n;
                arraybuffer[j * 8 + 6] = ptD;
                arraybuffer[j * 8 + 7] = blc_o + blc_q + blc_p;

                indicebuffer[j * 6 + 0] = j * 4;
                indicebuffer[j * 6 + 1] = j * 4 + 1;
                indicebuffer[j * 6 + 2] = j * 4 + 2;
                indicebuffer[j * 6 + 3] = j * 4;
                indicebuffer[j * 6 + 4] = j * 4 + 2;
                indicebuffer[j * 6 + 5] = j * 4 + 3;

                j += 1;
            }

            // +z / 0 / FRONT OK
            if (block.faces[0]) {
                arraybuffer[j * 8 + 0] = ptA;
                arraybuffer[j * 8 + 1] = blc_c + blc_s + blc_r;
                arraybuffer[j * 8 + 2] = ptB;
                arraybuffer[j * 8 + 3] = blc_a + blc_s + blc_t;
                arraybuffer[j * 8 + 4] = ptF;
                arraybuffer[j * 8 + 5] = blc_a + blc_k + blc_l;
                arraybuffer[j * 8 + 6] = ptE;
                arraybuffer[j * 8 + 7] = blc_c + blc_k + blc_j;

                indicebuffer[j * 6 + 0] = j * 4;
                indicebuffer[j * 6 + 1] = j * 4 + 1;
                indicebuffer[j * 6 + 2] = j * 4 + 2;
                indicebuffer[j * 6 + 3] = j * 4;
                indicebuffer[j * 6 + 4] = j * 4 + 2;
                indicebuffer[j * 6 + 5] = j * 4 + 3;

                j += 1;
            }

            // -z / 1 / BACK Ok
            if (block.faces[1]) {
                arraybuffer[j * 8 + 0] = ptC;
                arraybuffer[j * 8 + 1] = blc_d + blc_o + blc_n;
                arraybuffer[j * 8 + 2] = ptD;
                arraybuffer[j * 8 + 3] = blc_b + blc_o + blc_p;
                arraybuffer[j * 8 + 4] = ptH;
                arraybuffer[j * 8 + 5] = blc_b + blc_g + blc_h;
                arraybuffer[j * 8 + 6] = ptG;
                arraybuffer[j * 8 + 7] = blc_d + blc_g + blc_f;

                indicebuffer[j * 6 + 0] = j * 4;
                indicebuffer[j * 6 + 1] = j * 4 + 1;
                indicebuffer[j * 6 + 2] = j * 4 + 2;
                indicebuffer[j * 6 + 3] = j * 4;
                indicebuffer[j * 6 + 4] = j * 4 + 2;
                indicebuffer[j * 6 + 5] = j * 4 + 3;

                j += 1;
            }
        }

        return .{ .arraybuffer = arraybuffer, .indicebuffer = indicebuffer };
    }

    pub fn getBlock(self: *Self, x: usize, y: usize, z: usize) ?*custom_block {
        var chunkx: usize = x / 16;
        var chunkz: usize = z / 16;

        var blockx: usize = x - chunkx * 16;
        var blockz: usize = z - chunkz * 16;

        var keyChunk: usize = chunkx + chunkz * 8;
        var keyBlock: usize = utils.keyFromCoord(blockx, y, blockz);

        if (keyChunk >= self.chunks.len) {
            return null;
        } else if (keyBlock >= self.chunks[keyChunk].blocks.len) {
            return null;
        }

        return &self.chunks[keyChunk].blocks[keyBlock];
    }

    pub fn draw(self: *Self, ntexture: Texture) void {
        _ = ntexture;

        for (self.chunks) |*chunk| {
            if (chunk.loaded) {
                if (chunk.uploaded) {
                    std.debug.print("{s} {any} {any}\n", .{ "draw", chunk.x, chunk.y });

                    chunk.draw(self.program);
                } else {
                    std.debug.print("{s} {any} {any}\n", .{ "up", chunk.x, chunk.y });

                    chunk.upload(self);
                }
            }
        }
    }
};
