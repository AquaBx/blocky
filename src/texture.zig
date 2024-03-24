const std = @import("std");
const gl = @import("gl");
const read = std.fs.Dir.readFile;
const c = @import("c.zig");

pub const Texture = struct {

    const Self = @This();

    id: gl.GLuint,

    pub fn init() Self {
        
        var texture : gl.GLuint = 0;
        const path = "./dirt.png";

        var width:c_int = undefined;
        var height:c_int = undefined;

        var bin = @embedFile(path);

        var data = c.stbi_load_from_memory(bin.ptr,@intCast(bin.len),&width,&height,null,3);

        gl.genTextures(1, &texture);  
        gl.bindTexture(gl.TEXTURE_2D, texture);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
        gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);

        gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGB, width, height, 0, gl.RGB, gl.UNSIGNED_BYTE, &data[0]);
        gl.generateMipmap(gl.TEXTURE_2D);

        c.stbi_image_free(data);

        return .{
            .id = texture,
        };

    }

    pub fn delete(self: Self) void {
        gl.deleteProgram(self.id);
    }
};    