const std = @import("std");

const PROCESSING_DIR = "spool/processing";
const DONE_DIR = "spool/done";

pub fn process(file_path: []const u8, io: std.Io) !void {
    const cwd = std.Io.Dir.cwd();
    const gpa = std.heap.page_allocator;

    const task_path: []const u8 = try std.fs.path.join(gpa, &[_][]const u8{ PROCESSING_DIR, file_path });

    const file = try cwd.openFile(io, task_path, .{ .mode = .read_only });
    defer file.close(io);

    const new_dir = try cwd.openDir(io, DONE_DIR, .{});
    defer new_dir.close(io);

    try cwd.rename(task_path, new_dir, file_path, io);

    std.log.debug("task done {s}\n", .{file_path});
}
