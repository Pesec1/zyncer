const std = @import("std");
const zap = @import("zap");
const RoomWeb = @import("roomsweb.zig");

fn on_request(r: zap.Request) void {
    if (r.path) |the_path| {
        std.debug.print("PATH: {s}\n", .{the_path});
    }

    if (r.query) |the_query| {
        std.debug.print("QUERY: {s}\n", .{the_query});
    }

    r.sendBody("<html><body><h1>Hello from ZAP!!!</h1></body></html>") catch return;
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{
        .thread_safe = true,
    }){};
    const allocator = gpa.allocator();
    {
        var listener = zap.Endpoint.Listener.init(allocator, .{
            .port = 3000,
            .on_request = on_request,
            .public_folder = "static/",
            .log = true,
            .max_clients = 100000,
        });
        defer listener.deinit();
        var roomWeb = RoomWeb.init(allocator, "/rooms");
        defer roomWeb.deinit();

        try listener.register(roomWeb.endpoint());
        var uid: usize = undefined;
        uid = try roomWeb.rooms().addByName("fuck you");
        uid = try roomWeb.rooms().addByName("go fuck youself");

        try listener.listen();

        std.debug.print("Listening on 0.0.0.0:3000\n", .{});

        zap.start(.{
            .threads = 2,
            .workers = 1, // 1 worker enables sharing state between threads
        });
    }

    const has_leaked = gpa.detectLeaks();
    std.log.debug("Has leaked: {}", .{has_leaked});
}
