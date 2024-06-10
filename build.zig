const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = b.addModule("zebml", .{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // b.installArtifact(lib);

    const main_tests = b.addTest(.{
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const run_main_tests = b.addRunArtifact(main_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_main_tests.step);

    const lib = b.addStaticLibrary(.{
        .name = "zebml",
        .root_source_file = b.path("src/lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    const install_docs = b.addInstallDirectory(.{
        // running exe.getEmittedDocs() is what actually triggers generation
        // of the docs
        .source_dir = lib.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs",
    });

    // This creates a step that doesn't really do anything besides showing up in the output of `zig build -l` or
    // `zig build --help`...
    const docs_step = b.step("docs", "Copy documentation artifacts to prefix path");
    // ... but we depend on the previous step that actually installs our docs
    docs_step.dependOn(&install_docs.step);
}
