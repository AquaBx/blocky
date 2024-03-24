const custom_block = @import("block.zig").custom_block;
const utils = @import("utils.zig");
const std = @import("std");
const math = @import("zlm");
const shader = @import("../shader.zig");
const terrain = @import("./terrain.zig").Terrain;
const gl = @import("gl");

const allocator = std.heap.page_allocator;

pub const Chunk = struct {
    vao: gl.GLuint,
    vbo: gl.GLuint,
    ibo: gl.GLuint,
    ibosize: isize,
    loaded: bool,
    uploaded: bool,
    x: usize,
    y: usize,
    blocks: [65536]custom_block,

    const Self = @This();

    pub fn init(world_x: usize, world_y: usize) Self {
        var array: [65536]custom_block = undefined;

        for (0..16) |x| {
            for (0..16) |z| {
                var ny: u8 = utils.perlinNoise(world_x, world_y, x, z);

                for (0..256) |y| {
                    var local_id = utils.keyFromCoord(x, y, z);

                    if (y < ny) {
                        array[local_id] = custom_block.init(1);
                    } else {
                        array[local_id] = custom_block.init(0);
                    }
                }
            }
        }

        return .{
            .vao = 0,
            .vbo = 0,
            .ibo = 0,
            .ibosize = 0,
            .x = world_x,
            .y = world_y,
            .loaded = true,
            .uploaded = false,
            .blocks = array,
        };
    }

    pub fn upload(self: *Self, ter: *terrain) void {
        var retour = ter.optimize(&self.blocks, self.x, self.y);

        var arraybuffer = retour.arraybuffer;
        var indicebuffer = retour.indicebuffer;

        var BackgroundVertexArray: gl.GLuint = 0; // VAO
        var BackgroundVertexBuffer: gl.GLuint = 0; // VBO
        var IndexBuffer: gl.GLuint = 0; // IBO

        //VAO
        gl.genVertexArrays(1, &BackgroundVertexArray);
        gl.bindVertexArray(BackgroundVertexArray);

        //VBO
        var lenarraybuffer: isize = @intCast(arraybuffer.len);

        gl.genBuffers(1, &BackgroundVertexBuffer);
        gl.bindBuffer(gl.ARRAY_BUFFER, BackgroundVertexBuffer);

        gl.bufferData(gl.ARRAY_BUFFER, lenarraybuffer * @sizeOf(u32), &arraybuffer[0], gl.STATIC_DRAW);
        gl.enableVertexAttribArray(0);
        gl.vertexAttribIPointer(0, 1, gl.UNSIGNED_INT, 2 * @sizeOf(u32), null);
        gl.enableVertexAttribArray(1);
        gl.vertexAttribIPointer(1, 1, gl.UNSIGNED_INT, 2 * @sizeOf(u32), @ptrFromInt(1 * @sizeOf(u32)));

        //IBO
        var lenindicebuffer: isize = @intCast(indicebuffer.len);

        gl.genBuffers(1, &IndexBuffer);
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, IndexBuffer);
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, lenindicebuffer * @sizeOf(u32), &indicebuffer[0], gl.STATIC_DRAW);

        self.vao = BackgroundVertexArray;
        self.vbo = BackgroundVertexBuffer;
        self.ibo = IndexBuffer;
        self.ibosize = lenindicebuffer;
        self.uploaded = true;

        allocator.free(arraybuffer);
        allocator.free(indicebuffer);
    }

    pub fn draw(self: Self, program: shader.program) void {
        gl.bindVertexArray(self.vao);

        gl.uniform2f(gl.getUniformLocation(program.id, "chunkPos".ptr), @floatFromInt(self.x), @floatFromInt(self.y));

        gl.activeTexture(gl.TEXTURE0);
        gl.bindTexture(gl.TEXTURE_2D, 1);
        gl.drawElements(gl.TRIANGLES, @intCast(self.ibosize), gl.UNSIGNED_INT, null);
    }

    pub fn destroy(self: Self) void {
        gl.deleteVertexArrays(1, &self.vao);
        gl.deleteBuffers(1, &self.vbo);
    }
};
