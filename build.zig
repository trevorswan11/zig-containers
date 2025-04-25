const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    exe_mod.addImport("zig_containers_lib", lib_mod);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "zig_containers",
        .root_module = lib_mod,
    });
    b.installArtifact(lib);

    const exe = b.addExecutable(.{
        .name = "zig_containers",
        .root_module = exe_mod,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    addTestStep(b, lib_mod, exe_mod);
}

fn addTestStep(b: *std.Build, lib_mod: *std.Build.Module, exe_mod: *std.Build.Module) void {
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);

    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);
    test_step.dependOn(&run_exe_unit_tests.step);

    const gpa = std.heap.page_allocator;
    const paths = getZigSourceFiles(gpa, "src") catch {
        std.debug.print("Failed to collect source files\n", .{});
        return;
    };

    defer {
        for (paths.items) |p| gpa.free(p);
        paths.deinit();
    }

    for (paths.items) |path| {
        test_step.dependOn(&(b.addRunArtifact(b.addTest(.{
            .root_source_file = b.path(path),
        }))).step);
        // std.debug.print("Found File: {s}\n", .{path});
    }
}

fn getZigSourceFiles(allocator: std.mem.Allocator, directory: []const u8) !std.ArrayList([]const u8) {
    const cwd = std.fs.cwd();
    var dir = try cwd.openDir(directory, .{ .iterate = true });
    defer dir.close();

    var walker = try dir.walk(allocator);
    defer walker.deinit();

    var paths = std.ArrayList([]const u8).init(allocator);

    while (try walker.next()) |entry| {
        if (entry.kind != .file) continue;
        if (!std.mem.endsWith(u8, entry.basename, ".zig")) continue;
        if (std.mem.eql(u8, entry.basename, "main.zig")) continue;
        if (std.mem.eql(u8, entry.basename, "root.zig")) continue;

        const full_path = try std.fs.path.join(allocator, &.{ directory, entry.path });
        try paths.append(full_path);
    }

    return paths;
}
