const std = @import("std");

// fn addLocalModules(b: *std.Build, exe: *Compile) void {
// 
// }

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize
    });

    const exe = b.addExecutable(.{
        .name = "key_counter",
        .root_module = exe_mod
    });

    // Shader module
    const shader_content = b.addOptions();
    shader_content.addOption(
        [:0]const u8,
        "heatmap_shader",
        @embedFile("resources/shaders/heatmap.fsh")
    );
    exe.root_module.addOptions("shader_content", shader_content);

    // Stats module
    const stats = b.createModule(. {
        .root_source_file = b.path("src/stats/stats.zig")
    });
    exe.root_module.addImport("stats", stats);

    // Platform module
    const platform = b.createModule(. {
        .root_source_file = b.path("src/platform/platform.zig")
    });
    platform.addImport("stats", stats);
    exe.root_module.addImport("pf", platform);

    // Raylib
    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });

    const raylib = raylib_dep.module("raylib"); // main raylib module
    const raygui = raylib_dep.module("raygui"); // raygui module
    const raylib_artifact = raylib_dep.artifact("raylib"); // raylib C library

    exe.linkLibrary(raylib_artifact);
    exe.root_module.addImport("raylib", raylib);
    exe.root_module.addImport("raygui", raygui);

    // Platform
    exe.linkLibC();
    if (target.result.os.tag == .windows) {
        exe.linkSystemLibrary("user32");
    } else if (target.result.os.tag == .linux) {

    }

    // sqlite
    exe.addCSourceFile(.{
        .file = b.path("lib/sqlite-3510100/sqlite3.c"),
        .flags = &[_][]const u8{
            "-DSQLITE_THREADSAFE=1"
        },
    });
    stats.addIncludePath(b.path("lib/sqlite-3510100/"));
    exe.addIncludePath(b.path("lib/sqlite-3510100/"));
    
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run and build the app");
    run_step.dependOn(&run_cmd.step);
}
