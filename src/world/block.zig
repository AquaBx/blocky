pub const custom_block = struct {
    texture : u8,
    occlusion : [6][4]u2, // opacity = 0.75^(3-x)
    faces : [6]bool,

    const Self = @This();

    pub fn init(texture:u8) Self {

        var faces:[6]bool = .{true,true,true,true,true,true};

        return .{
            .texture = texture,
            .occlusion = undefined,
            .faces = faces,
        };
    }

    pub fn hide_face(self:*Self,id:u6) void {
        self.faces[id] = false;
    }

    pub fn occlude(self:*Self,face:u3,value0:u2,value1:u2,value2:u2,value3:u2) void{
        if ( self.faces[face] ) {
            self.occlusion[face][0] = value0;
            self.occlusion[face][1] = value1;
            self.occlusion[face][2] = value2;
            self.occlusion[face][3] = value3;
        }
    }
};