const std = @import("std");
const linked_list = @import("list.zig").List;

pub fn Stack(comptime T: type) type {
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

        /// Pushes an item to the top of the queue
        pub fn push(self: *Self, value: T) !void {
            try self.list.append(value);
        }

        /// Pops the item at the top of the stack
        pub fn pop(self: *Self) ?T {
            return self.list.popTail();
        }

        /// Returns the item at the top of the stack without removing it
        pub fn peek(self: *Self) ?T {
            return self.list.peekTail();
        }
    };
}

const testing = std.testing;

test "Stack push and pop basic functionality" {
    const allocator = testing.allocator;
    var stack = try Stack(i32).init(allocator);
    defer stack.deinit();

    try stack.push(10);
    try stack.push(20);
    try stack.push(30);

    try testing.expectEqual(@as(?i32, 30), stack.peek());
    try testing.expectEqual(@as(?i32, 30), stack.pop());
    try testing.expectEqual(@as(?i32, 20), stack.peek());
    try testing.expectEqual(@as(?i32, 20), stack.pop());
    try testing.expectEqual(@as(?i32, 10), stack.peek());
    try testing.expectEqual(@as(?i32, 10), stack.pop());
    try testing.expectEqual(@as(?i32, null), stack.peek());
    try testing.expectEqual(@as(?i32, null), stack.pop());
}

test "Stack handles empty pop and peek gracefully" {
    const allocator = testing.allocator;
    var stack = try Stack(u8).init(allocator);
    defer stack.deinit();

    try testing.expectEqual(@as(?u8, null), stack.pop());
    try testing.expectEqual(@as(?u8, null), stack.peek());
}

test "Stack can handle multiple push and pop cycles" {
    const allocator = testing.allocator;
    var stack = try Stack(i64).init(allocator);
    defer stack.deinit();

    // First cycle
    try stack.push(1);
    try stack.push(2);
    try stack.push(3);

    try testing.expectEqual(@as(?i64, 3), stack.pop());
    try testing.expectEqual(@as(?i64, 2), stack.pop());

    // Second cycle
    try stack.push(4);
    try stack.push(5);

    try testing.expectEqual(@as(?i64, 5), stack.pop());
    try testing.expectEqual(@as(?i64, 4), stack.pop());
    try testing.expectEqual(@as(?i64, 1), stack.pop());
    try testing.expectEqual(@as(?i64, null), stack.pop());
}

test "Stack works with complex types (structs)" {
    const Point = struct {
        x: i32,
        y: i32,
    };

    const allocator = testing.allocator;
    var stack = try Stack(Point).init(allocator);
    defer stack.deinit();

    try stack.push(Point{ .x = 1, .y = 2 });
    try stack.push(Point{ .x = 3, .y = 4 });

    if (stack.peek()) |point| {
        try testing.expectEqual(3, point.x);
        try testing.expectEqual(4, point.y);
    } else {
        return error.TestUnexpectedNull;
    }

    if (stack.pop()) |point| {
        try testing.expectEqual(3, point.x);
        try testing.expectEqual(4, point.y);
    } else {
        return error.TestUnexpectedNull;
    }

    if (stack.pop()) |point| {
        try testing.expectEqual(1, point.x);
        try testing.expectEqual(2, point.y);
    } else {
        return error.TestUnexpectedNull;
    }
}