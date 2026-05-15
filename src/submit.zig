const std = @import("std");
const queue = @import("queue.zig");

pub fn submit(file_path: []const u8, io : std.Io) !void {
    try queue.enqueue(file_path, io);
}
