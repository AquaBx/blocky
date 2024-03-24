const std = @import("std");
const glfw = @import("mach-glfw");
const gl = @import("gl");
const math = @import("zlm");

const camera = @import("camera.zig");
const shader = @import("shader.zig");

const Texture = @import("texture.zig").Texture;
const Terrain = @import("world/terrain.zig").Terrain;

const log = std.log.scoped(.Engine);

fn glGetProcAddress(p: glfw.GLProc, proc: [:0]const u8) ?gl.FunctionPointer {
    _ = p;
    return glfw.getProcAddress(proc);
}

/// Default GLFW error handling callback
fn errorCallback(error_code: glfw.ErrorCode, description: [:0]const u8) void {
    std.log.err("glfw: {}: {s}\n", .{ error_code, description });
}

fn errorGlCallback(source: gl.GLenum, _type: gl.GLenum, id: gl.GLuint, severity: gl.GLenum, length: gl.GLsizei, message: [*:0]const u8, userParam: ?*anyopaque) callconv(.C) void {
    _ = length;
    _ = id;
    _ = userParam;

    var source_name = switch (source) {
        gl.DEBUG_SOURCE_API => "API",
        gl.DEBUG_SOURCE_WINDOW_SYSTEM => "window system",
        gl.DEBUG_SOURCE_SHADER_COMPILER => "shader compiler",
        gl.DEBUG_SOURCE_THIRD_PARTY => "third party",
        gl.DEBUG_SOURCE_APPLICATION => "application",
        gl.DEBUG_SOURCE_OTHER => "other",
        else => "other",
    };

    var severity_name = switch (_type) {
        gl.DEBUG_TYPE_ERROR => "error",
        gl.DEBUG_TYPE_DEPRECATED_BEHAVIOR => "deprecated behaviour",
        gl.DEBUG_TYPE_UNDEFINED_BEHAVIOR => "undefined behaviour",
        gl.DEBUG_TYPE_PORTABILITY => "portability",
        gl.DEBUG_TYPE_PERFORMANCE => "performance",
        gl.DEBUG_TYPE_MARKER => "marker",
        gl.DEBUG_TYPE_PUSH_GROUP => "push group",
        gl.DEBUG_TYPE_POP_GROUP => "pop group",
        gl.DEBUG_TYPE_OTHER => "other",
        else => "other",
    };

    var type_name = switch (severity) {
        gl.DEBUG_SEVERITY_HIGH => "high",
        gl.DEBUG_SEVERITY_MEDIUM => "medium",
        gl.DEBUG_SEVERITY_LOW => "low",
        gl.DEBUG_SEVERITY_NOTIFICATION => "notification",
        else => "other",
    };

    var errorCode = gl.getError();

    std.log.err("GL ERROR[code : {?}, source: {s}, type: {s}, severity: {s}]: {s}\n", .{ errorCode, source_name, type_name, severity_name, message });
}

const vertex_data = struct {
    start: [2]f32,
    control1: [2]f32,
    control2: [2]f32,
    end: [2]f32,

    const Self = @This();

    pub fn layout() void {
        gl.enableVertexAttribArray(0);
        gl.vertexAttribPointer(0, 2, gl.FLOAT, 0, @sizeOf(Self), null);
        gl.enableVertexAttribArray(1);
        gl.vertexAttribPointer(1, 2, gl.FLOAT, 0, @sizeOf(Self), @ptrFromInt(@offsetOf(Self, "control1")));
        gl.enableVertexAttribArray(2);
        gl.vertexAttribPointer(2, 2, gl.FLOAT, 0, @sizeOf(Self), @ptrFromInt(@offsetOf(Self, "control2")));
        gl.enableVertexAttribArray(3);
        gl.vertexAttribPointer(3, 2, gl.FLOAT, 0, @sizeOf(Self), @ptrFromInt(@offsetOf(Self, "end")));
    }
};

pub fn resize(window: glfw.Window, width: u32, height: u32) void {
    _ = window;
    gl.viewport(0, 0, @bitCast(width), @bitCast(height));
}

pub fn main() !void {
    glfw.setErrorCallback(errorCallback);
    if (!glfw.init(.{})) {
        std.log.err("failed to initialize GLFW: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    }
    defer glfw.terminate();
    // Create our window

    var size = glfw.Window.Size{ .width = 1920, .height = 960 };

    const window = glfw.Window.create(size.width, size.height, "mach-glfw + zig-opengl", null, null, .{
        .opengl_profile = .opengl_core_profile,
        .context_version_major = 4,
        .context_version_minor = 5,
    }) orelse {
        std.log.err("failed to create GLFW window: {?s}", .{glfw.getErrorString()});
        std.process.exit(1);
    };
    defer window.destroy();
    // window.setFramebufferSizeCallback(resize);

    glfw.makeContextCurrent(window);
    glfw.swapInterval(1);

    const proc: glfw.GLProc = undefined;
    gl.load(proc, glGetProcAddress) catch |err| {
        std.debug.print("Error loading opengl functions: {}\n", .{err});
    };

    resize(window, size.width, size.height);

    gl.enable(gl.DEBUG_OUTPUT);
    gl.enable(gl.PROGRAM_POINT_SIZE);
    gl.enable(gl.DEPTH_TEST);
    gl.enable(gl.CULL_FACE);

    gl.pointSize(6.0);
    gl.debugMessageCallback(errorGlCallback, null);

    //

    var ntexture = Texture.init();
    var nterrain = try Terrain.init();
    defer nterrain.destroy();

    var cam = camera.camera.init(size.width, size.height, math.Vec3.new(0, 171, 0));
    window.setInputMode(glfw.Window.InputMode.cursor, glfw.Window.InputModeCursor.disabled);

    // Wait for the user to close the window.

    gl.clearColor(135.0 / 255.0, 206.0 / 255.0, 235.0 / 255.0, 1.0);

    var dt: f32 = 0;

    var cond: bool = true;

    while (cond and !window.shouldClose()) {
        glfw.setTime(0);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        size = window.getSize();
        resize(window, size.width, size.height);

        nterrain.program.use();

        cam.width = size.width;
        cam.height = size.height;
        cam.Matrix(75, 0.1, 1000.0, nterrain.program, "camMatrix");
        cam.Inputs(window, dt);

        // std.debug.print("\n{s}\n\n", .{"1"});

        nterrain.draw(ntexture);

        window.swapBuffers();
        glfw.pollEvents();

        dt = @floatCast(glfw.getTime());
        // cond = false;
    }
}
