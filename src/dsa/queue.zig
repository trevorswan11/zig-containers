const std = @import("std");
const linked_list = @import("list.zig").List;

pub fn Queue(comptime T: type) type {
    return struct {
        const Self = @This();

        list: linked_list(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{
                .allocator = allocator,
                .list = try linked_list(T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            self.list.deinit();
        }

        /// Pushes an item to the back of the queue
        pub fn push(self: *Self, value: T) !void {
            try self.list.append(value);
        }

        /// Pops the item at the front of the queue
        pub fn poll(self: *Self) ?T {
            return self.list.popHead();
        }

        /// Returns the item at the front of the queue without removing it
        pub fn peek(self: *Self) ?T {
            return self.list.peekHead();
        }
    };
}

const testing = std.testing;

test "Queue push and poll basic functionality" {
    const allocator = testing.allocator;
    var queue = try Queue(i32).init(allocator);
    defer queue.deinit();

    try queue.push(10);
    try queue.push(20);
    try queue.push(30);

    try testing.expectEqual(@as(?i32, 10), queue.peek());
    try testing.expectEqual(@as(?i32, 10), queue.poll());
    try testing.expectEqual(@as(?i32, 20), queue.peek());
    try testing.expectEqual(@as(?i32, 20), queue.poll());
    try testing.expectEqual(@as(?i32, 30), queue.peek());
    try testing.expectEqual(@as(?i32, 30), queue.poll());
    try testing.expectEqual(@as(?i32, null), queue.peek());
    try testing.expectEqual(@as(?i32, null), queue.poll());
}

test "Queue handles empty poll and peek gracefully" {
    const allocator = testing.allocator;
    var queue = try Queue(u8).init(allocator);
    defer queue.deinit();

    try testing.expectEqual(@as(?u8, null), queue.poll());
    try testing.expectEqual(@as(?u8, null), queue.peek());
}

test "Queue can handle multiple push and poll cycles" {
    const allocator = testing.allocator;
    var queue = try Queue(i64).init(allocator);
    defer queue.deinit();

    // First cycle
    try queue.push(1);
    try queue.push(2);
    try queue.push(3);

    try testing.expectEqual(@as(?i64, 1), queue.poll());
    try testing.expectEqual(@as(?i64, 2), queue.poll());

    // Second cycle
    try queue.push(4);
    try queue.push(5);

    try testing.expectEqual(@as(?i64, 3), queue.poll());
    try testing.expectEqual(@as(?i64, 4), queue.poll());
    try testing.expectEqual(@as(?i64, 5), queue.poll());
    try testing.expectEqual(@as(?i64, null), queue.poll());
}

test "Queue works with complex types (structs)" {
    const Point = struct {
        x: i32,
        y: i32,
    };

    const allocator = testing.allocator;
    var queue = try Queue(Point).init(allocator);
    defer queue.deinit();

    try queue.push(Point{ .x = 1, .y = 2 });
    try queue.push(Point{ .x = 3, .y = 4 });

    if (queue.peek()) |point| {
        try testing.expectEqual(1, point.x);
        try testing.expectEqual(2, point.y);
    } else {
        return error.TestUnexpectedNull;
    }

    if (queue.poll()) |point| {
        try testing.expectEqual(1, point.x);
        try testing.expectEqual(2, point.y);
    } else {
        return error.TestUnexpectedNull;
    }

    if (queue.poll()) |point| {
        try testing.expectEqual(3, point.x);
        try testing.expectEqual(4, point.y);
    } else {
        return error.TestUnexpectedNull;
    }
}
