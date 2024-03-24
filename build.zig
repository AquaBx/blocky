const std = @import("std");
// const glfw = @import("lib/mach-glfw/build.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zigrenderer",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const glfw_dep = b.dependency("mach_glfw", .{
        .target = target,
        .optimize = optimize,
    });

    // Now we link the resulting library,
    // passing in the artifact from our dependency
    exe.linkLibrary(glfw_dep.artifact("mach-glfw"));

    // Add the module to our package scope
    // Note the name here is the module that
    // you will import (`@import("mach-glfw")`)
    exe.addModule("mach-glfw", glfw_dep.module("mach-glfw"));

    // Use the mach-glfw .link helper here
    // to link the glfw library for us
    try @import("mach_glfw").link(b, exe);

    // Same as above for our gl module,
    // because we copied the gl code into the project
    // we instead just create the module inline
    exe.addModule("gl", b.createModule(.{
        .source_file = .{ .path = "libs/opengl.zig" },
    }));

    exe.addModule("zlm", b.createModule(.{
        .source_file = .{ .path = "libs/zlm.zig" },
    }));

    exe.addCSourceFile(.{
        .file = std.build.LazyPath.relative("libs/stb_image/stb_image_impl.c"),
        .flags = &[_][]const u8{"-std=c99"},
    });

    exe.addIncludePath(std.build.LazyPath.relative("libs/stb_image"));

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
