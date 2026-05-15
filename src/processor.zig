const std = @import("std");

const PROCESSING_DIR = "spool/processing";
const DONE_DIR = "spool/done";

pub fn process(job_id: []const u8, io: std.Io) !void {
    const cwd = std.Io.Dir.cwd();
    const gpa = std.heap.page_allocator;

    const job_path: []const u8 = try std.fs.path.join(gpa, &[_][]const u8{ PROCESSING_DIR, job_id });
    defer gpa.free(job_path);

    var job_dir = try cwd.openDir(io, job_path, .{});
    defer job_dir.close(io);

    var file = try job_dir.openFile(io, "payload.txt", .{ .mode = .read_only });
    defer file.close(io);

    var buffer: [1024]u8 = undefined;
    var reader = file.reader(io, &buffer);
    var reader_int = &reader.interface;

    var logs_file = try cwd.openFile(io, "logs/logs.txt", .{ .mode = .write_only });
    defer logs_file.close(io);

    const stat = try logs_file.stat(io);

    var offset = stat.size;
    _ = try logs_file.writePositionalAll(io, &[_][]const u8{job_id}, offset);

    offset += job_id.len;

    while (true) {
        const line = try reader_int.takeDelimiter('\n');
        if (line) |l| {
            if (l.len == 0) break;
            _ = try logs_file.writePositionalAll(io, &[_][]const u8{l}, offset);
            offset += l.len;
        } else break;
    }

    const new_dir = try cwd.openDir(io, DONE_DIR, .{});
    defer new_dir.close(io);

    try cwd.rename(job_path, new_dir, job_id, io);

    std.log.debug("task done {s}\n", .{job_id});
}
