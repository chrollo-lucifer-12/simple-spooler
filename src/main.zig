const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const gpa = std.heap.page_allocator;
    const mini = init.minimal;

    var args_it = try mini.args.iterateAllocator(gpa);

    _ = args_it.skip();

    var file_path: []const u8 = undefined;

    if (args_it.next()) |task_type| {
        if (std.mem.eql(u8, task_type, "submit")) {
            if (args_it.next()) |path| {
                file_path = path;
            }
        }
    } else {
        return;
    }

    std.debug.print("{s}\n", .{file_path});
}
