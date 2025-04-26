const std = @import("std");

/// The name given to all built objects. By convention, this name should be snake case
const PROJECT_NAME: []const u8 = "zig_containers";

/// The name that will be used when importing your library into your codebase.
/// By convention, this name should be snake case
const LIB_IMPORT_NAME: []const u8 = "zig_containers_lib";

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

    installLib(b, lib_mod, exe_mod);
    addRunStep(b, installExe(b, exe_mod));
    addTestStep(b, lib_mod, exe_mod);
}

fn installLib(b: *std.Build, lib_mod: *std.Build.Module, exe_mod: *std.Build.Module) void {
    exe_mod.addImport(LIB_IMPORT_NAME, lib_mod);

    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = PROJECT_NAME,
        .root_module = lib_mod,
    });
    b.installArtifact(lib);
}

fn installExe(b: *std.Build, exe_mod: *std.Build.Module) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = PROJECT_NAME,
        .root_module = exe_mod,
    });

    b.installArtifact(exe);
    return exe;
}

fn addRunStep(b: *std.Build, exe: *std.Build.Step.Compile) void {
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}

fn addTestStep(b: *std.Build, lib_mod: *std.Build.Module, exe_mod: *std.Build.Module) void {
    const test_step = b.step("test", "Run unit tests");

    addLibTestStep(b, lib_mod, test_step);
    addExeTestStep(b, exe_mod, test_step);
    addSourceTests(b, test_step);
}

/// Adds all tests associated with the root lib module, conventionally `root.zig`
fn addLibTestStep(b: *std.Build, lib_mod: *std.Build.Module, test_step: *std.Build.Step) void {
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    test_step.dependOn(&run_lib_unit_tests.step);
}

/// Adds all tests associated with the root exe module, conventionally `main.zig`
fn addExeTestStep(b: *std.Build, exe_mod: *std.Build.Module, test_step: *std.Build.Step) void {
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    test_step.dependOn(&run_exe_unit_tests.step);
}

/// Adds all other source files to the test step. This can increase the compile time when running 
/// `zig build test`, but correctly allows all tests in the src directory to be executed correctly
fn addSourceTests(b: *std.Build, test_step: *std.Build.Step) void {
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

/// Helper function which returns a list of all .zig files in the given directory, excluding main.zig
/// and root.zig by convention 
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
