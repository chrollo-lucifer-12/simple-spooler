const std = @import("std");
const processor = @import("processor.zig");
const queue = @import("queue.zig");

const PENDING_DIR = "spool/pending";
const PROCESSING_DIR = "spool/processing";

pub fn worker(io: std.Io) !void {
    const cwd = std.Io.Dir.cwd();

    const gpa = std.heap.page_allocator;

    const new_dir = try cwd.openDir(io, PROCESSING_DIR, .{});
    defer new_dir.close(io);

    while (true) {
        const pending_dir = try cwd.openDir(io, PENDING_DIR, .{ .iterate = true });
        defer pending_dir.close(io);

        var w = pending_dir.iterate();

        var did_work = false;

        while (try w.next(io)) |e| {
            if (e.kind != .directory) {
                continue;
            }

            did_work = true;

            const old_path: []const u8 = try std.fs.path.join(gpa, &[_][]const u8{ PENDING_DIR, e.name });
            defer gpa.free(old_path);

            try cwd.rename(old_path, new_dir, e.name, io);

            std.log.debug("claimed job : {s}\n", .{e.name});

            try processor.process(e.name, io);
        }

        // if (did_work) {
        //     std.Io.sleep(io, std.Io.Duration.toSeconds(1), std.Io.Clock{});
        // }
    }
}
