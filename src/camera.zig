const math = @import("zlm");
const gl = @import("gl");
const shaderprog = @import("shader.zig");
const glfw = @import("mach-glfw");
const std = @import("std");

pub fn createPerspective(fov: f32, aspect: f32, near: f32, far: f32) math.Mat4 {
    const tanHalfFovy = @tan(fov / 2);

    var result = math.Mat4.zero;
    result.fields[0][0] = near / (aspect * tanHalfFovy);
    result.fields[1][1] = near / (tanHalfFovy);
    result.fields[2][2] = -(far + near) / (far - near);
    result.fields[3][2] = -1;
    result.fields[2][3] = -2 * far * near / (far - near);

    return result;
}

pub fn createLook(eye: math.Vec3, direction: math.Vec3, up: math.Vec3) math.Mat4 {
    const f = direction.normalize();
    const s = math.Vec3.cross(up, f).normalize();
    const u = math.Vec3.cross(f, s);

    var result = math.Mat4.identity;
    result.fields[0][0] = s.x;
    result.fields[0][1] = s.y;
    result.fields[0][2] = s.z;
    result.fields[1][0] = u.x;
    result.fields[1][1] = u.y;
    result.fields[1][2] = u.z;
    result.fields[2][0] = f.x;
    result.fields[2][1] = f.y;
    result.fields[2][2] = f.z;
    result.fields[0][3] = -math.Vec3.dot(s, eye);
    result.fields[1][3] = -math.Vec3.dot(u, eye);
    result.fields[2][3] = -math.Vec3.dot(f, eye);
    return result;
}

pub fn rotate(direction: math.Vec3, angle: f32) math.Vec3 {
    var result = math.Vec3.zero;

    result.x = direction.x;
    result.y = @sin(angle) * direction.y;
    result.z = @cos(angle) * direction.z;

    return result;
}

pub const camera = struct {
    width: u32,
    height: u32,
    position: math.Vec3,
    up: math.Vec3 = math.Vec3.new(0.0, 1.0, 0.0),
    orientation: math.Vec3 = math.Vec3.new(0.0, 0.0, 1.0),
    theta: f32,
    phi: f32,

    const Self = @This();

    pub fn init(width: u32, height: u32, position: math.Vec3) Self {
        return Self{
            .width = width,
            .height = height,
            .position = position,
            .theta = 0,
            .phi = 0,
        };
    }

    pub fn Matrix(self: *Self, FOVdeg: f32, nearPlane: f32, farPlane: f32, shader: shaderprog.program, uniform: []const u8) void {
        var view = math.Mat4.createLookAt(self.position, self.position.add(self.orientation), self.up);
        var proj = math.Mat4.createPerspective(math.toRadians(FOVdeg), @as(f32, @floatFromInt(self.width)) / @as(f32, @floatFromInt(self.height)), nearPlane, farPlane);

        var loca = gl.getUniformLocation(shader.id, uniform.ptr);
        var ptr: [*c]const gl.GLfloat = &view.mul(proj).fields[0][0];
        gl.uniformMatrix4fv(loca, 1, gl.FALSE, ptr);
    }

    pub fn Inputs(self: *Self, window: glfw.Window, dt: f32) void {
        // std.debug.print("{} {}\n", .{ self.position, self.theta });

        // avancer reculer
        if (window.getKey(glfw.Key.w) == glfw.Action.press) {
            self.position.x += @cos(self.theta) * dt * 15.0;
            self.position.z += @sin(self.theta) * dt * 15.0;
        }
        if (window.getKey(glfw.Key.s) == glfw.Action.press) {
            self.position.x -= @cos(self.theta) * dt * 15.0;
            self.position.z -= @sin(self.theta) * dt * 15.0;
        }

        // straf
        if (window.getKey(glfw.Key.a) == glfw.Action.press) {
            self.position.x -= @sin(self.theta) * dt * 15.0;
            self.position.z += @cos(self.theta) * dt * 15.0;
        }
        if (window.getKey(glfw.Key.d) == glfw.Action.press) {
            self.position.x += @sin(self.theta) * dt * 15.0;
            self.position.z -= @cos(self.theta) * dt * 15.0;
        }

        // monter descendre
        if (window.getKey(glfw.Key.space) == glfw.Action.press) {
            self.position.y += dt * 15.0;
        }
        if (window.getKey(glfw.Key.left_shift) == glfw.Action.press) {
            self.position.y -= dt * 15.0;
        }

        // souris

        var mousePos = window.getCursorPos();

        if (mousePos.xpos != 0.0 or mousePos.ypos != 0.0) {
            var floatWidth: f32 = @floatFromInt(self.width);
            var floatHeight: f32 = @floatFromInt(self.height);

            var rotX: f64 = -(mousePos.xpos) / floatWidth;
            var rotY: f64 = -(mousePos.ypos) / floatHeight;

            var anglex: f32 = @floatCast(rotX * dt / 10 * floatWidth);
            var angley: f32 = @floatCast(rotY * dt / 10 * floatHeight);

            self.theta += anglex;
            self.phi += angley;

            self.theta = @mod(self.theta, 2 * 3.14);
            self.phi = @min(self.phi, 1.57);
            self.phi = @max(self.phi, -1.57);

            self.orientation.x = @cos(self.theta) * @cos(self.phi);
            self.orientation.y = @sin(self.phi);
            self.orientation.z = @sin(self.theta) * @cos(self.phi);

            window.setCursorPos(0, 0);
        }
    }
};
