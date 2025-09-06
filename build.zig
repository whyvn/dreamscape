const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exec = b.addExecutable(.{
        .name = "dreamscape",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize
        })
    });

    const zlm_module = b.dependency("zlm", .{}).module("zlm");
    exec.root_module.addImport("zlm", zlm_module);

    const zstbi = b.dependency("zstbi", .{});
    exec.root_module.addImport("zstbi", zstbi.module("root"));

    exec.linkSystemLibrary("glfw");
    exec.linkSystemLibrary("GL");
    exec.addIncludePath(b.path("third_party/gl"));
    exec.addIncludePath(b.path("third_party"));
    exec.linkLibC();
    exec.addCSourceFile(.{
        .file = b.path("third_party/gl/glad/glad.c")
    });

    b.installArtifact(exec);

    const run_exec = b.addRunArtifact(exec);
    const run_step = b.step("run", "run the app");
    if(b.args) |args| run_exec.addArgs(args);
    run_step.dependOn(&run_exec.step);
}
