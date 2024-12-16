const std = @import("std");

pub fn build(b: *std.Build) void {
    const exec = b.addExecutable(.{ .name = "dreamscape", .root_source_file = b.path("src/main.zig"), .target = b.standardTargetOptions(.{}), .optimize = b.standardOptimizeOption(.{}) });

    b.installArtifact(exec);

    const run_exec = b.addRunArtifact(exec);
    const run_step = b.step("run", "run the app");
    run_step.dependOn(&run_exec.step);
}
