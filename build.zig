const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "matroska-reader",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });

    const zigargs_dep = b.dependency("zigargs", .{
        // .target = target,
        // .optimize = optimize,
    });
    exe.addModule("zigargs", zigargs_dep.module("args"));

    b.installArtifact(exe);
    const run_cmd = b.addRunArtifact(exe);

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the application");
    run_step.dependOn(&run_cmd.step);

    const unit_tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    unit_tests.addModule("zigargs", zigargs_dep.module("args"));

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const install_docs = b.addInstallDirectory(.{
        // running exe.getEmittedDocs() is what actually triggers generation
        // of the docs
        .source_dir = exe.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    // This creates a step that doesn't really do anything besides showing up in the output of `zig build -l` or
    // `zig build --help`...
    const docs_step = b.step("docs", "Copy documentation artifacts to prefix path");
    // ... but we depend on the previous step that actually installs our docs
    docs_step.dependOn(&install_docs.step);
}
