const std = @import("std");
const zap = @import("zap");
const Rooms = @import("rooms.zig");
const Room = Rooms.Room;

alloc: std.mem.Allocator = undefined,
ep: zap.Endpoint = undefined,
_rooms: Rooms = undefined,

pub const Self = @This();

pub fn init(
    a: std.mem.Allocator,
    user_path: []const u8,
) Self {
    return .{ .alloc = a, ._rooms = Rooms.init(a), .ep = zap.Endpoint.init(.{
        .path = user_path,
        .get = getUser,
    }) };
}

pub fn deinit(self: *Self) void {
    self._rooms.deinit();
}

pub fn rooms(self: *Self) *Rooms {
    return &self._rooms;
}

fn roomIdFromPath(self: *Self, path: []const u8) ?usize {
    if (path.len >= self.ep.settings.path.len + 2) {
        if (path[self.ep.settings.path.len] != '/') {
            return null;
        }
        const idstr = path[self.ep.settings.path.len + 1 ..];
        return std.fmt.parseUnsigned(usize, idstr, 10) catch null;
    }
    return null;
}

fn getUser(e: *zap.Endpoint, r: zap.Request) void {
    const self: *Self = @fieldParentPtr("ep", e);

    if (r.path) |path| {
        var jsonbuf: [256]u8 = undefined;
        if (self.roomIdFromPath(path)) |id| {
            if (self._rooms.get(id)) |room| {
                if (zap.stringifyBuf(&jsonbuf, room, .{})) |json| {
                    r.sendJson(json) catch return;
                }
            }
        }
    }
}

pub fn endpoint(self: *Self) *zap.Endpoint {
    return &self.ep;
}
