const std = @import("std");

const PENDING_DIR = "spool/pending";
const TASKS_DIR = "jobs";

const Job = struct { id: []u8, file: []const u8, status: []const u8 };

fn generateJobID(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        "{d}",
        .{std.Io.Clock.real.now(io)},
    );
}

pub fn enqueue(file_path: []const u8, io: std.Io) !void {
    const cwd = std.Io.Dir.cwd();

    const gpa = std.heap.page_allocator;

    const job_id = try generateJobID(gpa, io);
    const dir_path = try std.fs.path.join(gpa, &[_][]const u8{ PENDING_DIR, job_id });
    defer gpa.free(dir_path);

    try cwd.createDir(io, dir_path, @enumFromInt(0o755));

    const full_path = try std.fs.path.join(gpa, &.{
        TASKS_DIR,
        file_path,
    });
    defer gpa.free(full_path);

    const pending_dir = try cwd.openDir(io, dir_path, .{});
    defer pending_dir.close(io);

    try cwd.copyFile(full_path, pending_dir, "payload.txt", io, .{});

    const job = Job{ .id = job_id, .file = file_path, .status = "pending" };

    const json: []const u8 = try std.json.Stringify.valueAlloc(gpa, job, .{ .whitespace = .indent_2 });

    const json_path = try std.fs.path.join(gpa, &.{ dir_path, "job.json" });
    defer gpa.free(json_path);

    const json_file = try cwd.createFile(io, json_path, .{});
    defer json_file.close(io);

    try json_file.writePositionalAll(io, json, 0);
}
