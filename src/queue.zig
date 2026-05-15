const std = @import("std");

const PENDING_DIR = "spool/pending";
const TASKS_DIR = "jobs";

pub fn enqueue(file_path: []const u8, io: std.Io) !void {
    const cwd = std.Io.Dir.cwd();
    const gpa = std.heap.page_allocator;

    const dir = cwd.openDir(io, PENDING_DIR, .{}) catch |err| {
        std.log.err("{}\n", .{err});
        return err;
    };
    defer dir.close(io);

    const full_path = try std.fs.path.join(gpa, &.{
        TASKS_DIR,
        file_path,
    });
    defer gpa.free(full_path);

    try cwd.copyFile(full_path, dir, file_path, io, .{});
}
