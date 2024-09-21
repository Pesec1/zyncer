const std = @import("std");

alloc: std.mem.Allocator = undefined,
rooms: std.AutoHashMap(usize, InternalRoom) = undefined,
lock: std.Thread.Mutex = undefined,
count: usize = 0,

pub const Self = @This();

pub const InternalRoom = struct {
    id: usize = 0,
    name: u8,
    namebuf: [64]u8,
    namelen: usize,
};

pub const Room = struct {
    id: usize = 0,
    name: []const u8,
};

pub fn init(a: std.mem.Allocator) Self {
    return .{
        .alloc = a,
        .rooms = std.AutoHashMap(usize, InternalRoom).init(a),
        .lock = std.Thread.Mutex{},
    };
}

pub fn deinit(self: *Self) void {
    self.rooms.deinit();
}

pub fn addByName(self: *Self, name: ?[]const u8) !usize {
    var room: InternalRoom = undefined;
    room.namelen = 0;

    if (name) |n| {
        @memcpy(room.namebuf[0..n.len], n);
        room.namelen = n.len;
    }
    self.lock.lock();
    defer self.lock.unlock();
    room.id = self.count + 1;
    if (self.rooms.put(room.id, room)) {
        self.count += 1;
        return room.id;
    } else |err| {
        std.debug.print("addByName error: {}\n", .{err});
        return err;
    }
}

pub fn delete(self: *Self, id: usize) bool {
    self.lock.lock();
    defer self.lock.unlock();

    const is_del = self.rooms.remove(id);
    if (is_del) {
        self.count -= 1;
    }
    return is_del;
}

pub fn get(self: *Self, id: usize) ?Room {
    if (self.rooms.getPtr(id)) |pRoom| {
        return .{
            .id = pRoom.id,
            .name = pRoom.namebuf[0..pRoom.namelen],
        };
    }
    return null;
}
