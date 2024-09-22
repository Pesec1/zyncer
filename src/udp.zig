const std = @import("std");
const os = std.os;
//https://gist.github.com/tetsu-koba/9afbab28bb12cb66e7359d13b043335b
const Socket = struct {
    address: std.net.Address,
    socket: std.posix.socket_t,

    fn init(ip: []const u8, port: u16) !Socket {
        const parsed_address = try std.net.Address.parseIp4(ip, port);
        const sock = try std.posix.socket(std.c.AF.INET, std.c.SOCK.DGRAM, 0);
        errdefer os.closeSocket(sock);
        return Socket{ .address = parsed_address, .socket = sock };
    }

    fn bind(self: *Socket) !void {
        try std.posix.bind(self.socket, &self.address.any, self.address.getOsSockLen());
    }

    fn listen(self: *Socket) !void {
        var buffer: [1024]u8 = undefined;
        var cliaddr: std.os.linux.sockaddr = undefined;
        var claddrlen: std.posix.socklen_t = @sizeOf(os.linux.sockaddr);
        while (true) {
            const received_bytes = try std.posix.recvfrom(self.socket, buffer[0..], 0, &cliaddr, &claddrlen);
            std.debug.print("Recieved {d} bytes: {s}\n", .{ received_bytes, buffer[0..received_bytes] });
            const msg = "HI CLIENT HOW ARE YOu";
            const sent_bytes = try std.posix.sendto(self.socket, msg, 0, &cliaddr, claddrlen);
            std.debug.print("SENDED data {any}\n", .{sent_bytes});
        }
    }
};

pub fn main() !void {
    var socket = try Socket.init("127.0.0.1", 4000);
    try socket.bind();
    try socket.listen();
}
