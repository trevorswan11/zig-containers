const std = @import("std");
const linked_list = @import("list.zig").List;

pub fn Deque(comptime T: type) type {
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

        /// Pushes an item to the front (head) of the deque
        pub fn pushHead(self: *Self, value: T) !void {
            try self.list.prepend(value);
        }

        /// Pops the item at the front (head) of the deque
        pub fn popHead(self: *Self) ?T {
            return self.list.popHead();
        }

        /// Returns the item at the front (head) without removing it
        pub fn peekHead(self: *Self) ?T {
            return self.list.peekHead();
        }

        /// Pushes an item to the back (tail) of the deque
        pub fn pushTail(self: *Self, value: T) !void {
            try self.list.append(value);
        }

        /// Pops the item at the back (tail) of the deque
        pub fn popTail(self: *Self) ?T {
            return self.list.popTail();
        }

        /// Returns the item at the back (tail) without removing it
        pub fn peekTail(self: *Self) ?T {
            return self.list.peekTail();
        }
    };
}

const testing = std.testing;

test "Deque pushHead and popHead" {
    const allocator = testing.allocator;
    var deque = try Deque(i32).init(allocator);
    defer deque.deinit();

    try deque.pushHead(1);
    try deque.pushHead(2); // Front is now: 2, 1

    try testing.expectEqual(@as(?i32, 2), deque.peekHead());
    try testing.expectEqual(@as(?i32, 2), deque.popHead());
    try testing.expectEqual(@as(?i32, 1), deque.popHead());
    try testing.expectEqual(@as(?i32, null), deque.popHead());
}

test "Deque pushTail and popTail" {
    const allocator = testing.allocator;
    var deque = try Deque(i32).init(allocator);
    defer deque.deinit();

    try deque.pushTail(1);
    try deque.pushTail(2); // Back is now: 1, 2

    try testing.expectEqual(@as(?i32, 2), deque.peekTail());
    try testing.expectEqual(@as(?i32, 2), deque.popTail());
    try testing.expectEqual(@as(?i32, 1), deque.popTail());
    try testing.expectEqual(@as(?i32, null), deque.popTail());
}

test "Deque mixed pushHead and pushTail" {
    const allocator = testing.allocator;
    var deque = try Deque(i32).init(allocator);
    defer deque.deinit();

    try deque.pushHead(2); // deque: 2
    try deque.pushTail(3); // deque: 2, 3
    try deque.pushHead(1); // deque: 1, 2, 3
    try deque.pushTail(4); // deque: 1, 2, 3, 4

    try testing.expectEqual(@as(?i32, 1), deque.peekHead());
    try testing.expectEqual(@as(?i32, 4), deque.peekTail());

    try testing.expectEqual(@as(?i32, 1), deque.popHead());
    try testing.expectEqual(@as(?i32, 4), deque.popTail());
    try testing.expectEqual(@as(?i32, 2), deque.popHead());
    try testing.expectEqual(@as(?i32, 3), deque.popTail());
    try testing.expectEqual(@as(?i32, null), deque.popHead());
}

test "Deque empty pop and peek" {
    const allocator = testing.allocator;
    var deque = try Deque(i32).init(allocator);
    defer deque.deinit();

    try testing.expectEqual(@as(?i32, null), deque.popHead());
    try testing.expectEqual(@as(?i32, null), deque.popTail());
    try testing.expectEqual(@as(?i32, null), deque.peekHead());
    try testing.expectEqual(@as(?i32, null), deque.peekTail());
}
