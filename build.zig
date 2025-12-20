const std = @import("std");

pub fn build(b: *std.Build) void {
    const exe = b.addExecutable(.{
        .root_module = b.createModule(.{
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
            .root_source_file = b.path("src/main.zig"),
        }),
        .name = "uwa",
    });
    b.installArtifact(exe);

    const run_exe = b.addRunArtifact(exe);
    if (b.args) |args| run_exe.addArgs(args);

    const run_step = b.step("run", "run uwa");
    run_step.dependOn(&run_exe.step);
}
