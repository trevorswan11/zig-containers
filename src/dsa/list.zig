const std = @import("std");

pub fn List(comptime T: type) type {
    return struct {
        const Self = @This();

        len: usize = 0,
        head: ?*Node = null,
        tail: ?*Node = null,
        allocator: std.mem.Allocator,

        pub const Node = struct {
            value: T,
            next: ?*Node = null,
            prev: ?*Node = null,
        };

        pub fn init(allocator: std.mem.Allocator) !Self {
            return Self{ .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.clear();
        }

        /// Inserts a value at the tail of the list
        pub fn prepend(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.* = Node{
                .value = value,
                .next = self.head,
            };

            if (self.head) |head_node| {
                head_node.prev = node;
            } else {
                self.tail = node;
            }

            self.head = node;
            self.len += 1;
        }

        /// Inserts a value at the head of the list
        pub fn append(self: *Self, value: T) !void {
            const node = try self.allocator.create(Node);
            node.* = Node{
                .value = value,
                .prev = self.tail,
            };

            if (self.tail) |tail_node| {
                tail_node.next = node;
            } else {
                self.head = node;
            }

            self.tail = node;
            self.len += 1;
        }

        /// Returns and removes the value stored at the list's head
        pub fn popHead(self: *Self) ?T {
            if (self.head == null) {
                return null;
            }

            const head_node = self.head.?;
            const to_return = head_node.value;

            if (head_node.next) |next_node| {
                self.head = next_node;
                self.head.?.prev = null;
                self.allocator.destroy(head_node);
            } else {
                self.head = null;
                self.tail = null;
                self.allocator.destroy(head_node);
            }

            self.len -= 1;
            return to_return;
        }

        /// Returns the value stored at the list's head without removing it
        pub fn peekHead(self: *Self) ?T {
            return if (self.head == null) null else self.head.?.value;
        }

        /// Returns and removes the value stored at the list's tail
        pub fn popTail(self: *Self) ?T {
            if (self.tail == null) {
                return null;
            }

            const tail_node = self.tail.?;
            const to_return = tail_node.value;

            if (tail_node.prev) |prev_node| {
                self.tail = prev_node;
                self.tail.?.next = null;
                self.allocator.destroy(tail_node);
            } else {
                self.head = null;
                self.tail = null;
                self.allocator.destroy(tail_node);
            }

            self.len -= 1;
            return to_return;
        }

        /// Returns the value stored at the list's tail without removing it
        pub fn peekTail(self: *Self) ?T {
            return if (self.tail == null) null else self.tail.?.value;
        }

        /// Inserts a new node with given value at provided index in the list
        pub fn insert(self: *Self, index: usize, value: T) !void {
            if (index > self.len) {
                return error.IndexOutOfBounds;
            }

            const new_node = try self.allocator.create(Node);
            new_node.* = Node{ .value = value };

            if (index == 0) {
                new_node.next = self.head;
                new_node.prev = null;

                if (self.head) |head| {
                    head.prev = new_node;
                } else {
                    self.tail = new_node;
                }

                self.head = new_node;
            } else if (index == self.len) {
                new_node.prev = self.tail;
                new_node.next = null;

                if (self.tail) |tail| {
                    tail.next = new_node;
                } else {
                    self.head = new_node;
                }

                self.tail = new_node;
            } else {
                var current = self.head;
                var idx: usize = 0;

                while (current) |node| : (idx += 1) {
                    if (idx == index) {
                        new_node.prev = node.prev;
                        new_node.next = node;

                        if (node.prev) |prev| {
                            prev.next = new_node;
                        }
                        node.prev = new_node;

                        break;
                    }

                    current = node.next;
                }
            }

            self.len += 1;
        }

        /// Gets the value at a specific index in the list without removing it
        pub fn get(self: *Self, index: usize) !T {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }

            var current = self.head;
            var idx: usize = 0;

            while (current) |node| {
                if (idx == index) {
                    return node.value;
                }
                current = node.next;
                idx += 1;
            }

            unreachable;
        }

        /// Removes and returns the value at the index in the list
        pub fn remove(self: *Self, index: usize) !T {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }

            var current = self.head;
            var idx: usize = 0;

            while (current) |node| {
                if (idx == index) {
                    const value = node.value;

                    if (node.prev) |prev| {
                        prev.next = node.next;
                    } else {
                        self.head = node.next;
                    }

                    if (node.next) |next| {
                        next.prev = node.prev;
                    } else {
                        self.tail = node.prev;
                    }

                    self.allocator.destroy(node);
                    self.len -= 1;

                    return value;
                }

                current = node.next;
                idx += 1;
            }

            unreachable;
        }

        /// Removes the value at the given index without returing the value
        pub fn discard(self: *Self, index: usize) !void {
            if (index >= self.len) {
                return error.IndexOutOfBounds;
            }

            var current = self.head;
            var idx: usize = 0;

            while (current) |node| {
                if (idx == index) {
                    if (node.prev) |prev| {
                        prev.next = node.next;
                    } else {
                        self.head = node.next;
                    }

                    if (node.next) |next| {
                        next.prev = node.prev;
                    } else {
                        self.tail = node.prev;
                    }

                    self.allocator.destroy(node);
                    self.len -= 1;

                    return;
                }

                current = node.next;
                idx += 1;
            }

            unreachable;
        }

        /// Returns whether or not the list contains any elements
        pub fn empty(self: *Self) bool {
            return self.len == 0;
        }

        /// Clears all nodes from the list
        pub fn clear(self: *Self) void {
            var current = self.head;
            while (current) |node| {
                const next = node.next;
                self.allocator.destroy(node);
                current = next;
            }

            self.head = null;
            self.tail = null;
            self.len = 0;
        }

        pub fn print(self: *Self) void {
            std.debug.print("[ null", .{});
            var current = self.head;
            while (current) |node| {
                std.debug.print(" -> {}", .{node.value});
                current = node.next;
            }
            std.debug.print(" -> null ]\n", .{});
        }

        /// Returns an iterator pointing to the head of the list
        pub fn begin(self: *Self) Iterator {
            return Iterator{ .current = self.head };
        }

        /// Returns an iterator pointing to the tail of the list
        pub fn end(self: *Self) Iterator {
            return Iterator{ .current = self.tail };
        }

        pub const Iterator = struct {
            current: ?*Node = null,

            pub fn next(self: *Iterator) ?*T {
                if (self.current) |node| {
                    const value_ptr = &node.value;
                    self.current = node.next;
                    return value_ptr;
                }
                return null;
            }

            pub fn prev(self: *Iterator) ?*T {
                if (self.current) |node| {
                    const value_ptr = &node.value;
                    self.current = node.prev;
                    return value_ptr;
                }
                return null;
            }

            pub fn begin(self: *Iterator) void {
                while (self.current) |node| {
                    self.current = node.prev;
                }
                self.current = self.current.?.next;
            }

            pub fn end(self: *Iterator) void {
                while (self.current) |node| {
                    self.current = node.next;
                }
                self.current = self.current.?.prev;
            }
        };
    };
}

// The following tests were generated by chatgpt to see what it knows about zig...
const testing = std.testing;
const expect = testing.expect;

test "initialize empty list" {
    const allocator = std.heap.page_allocator;
    var test_list = try List(u8).init(allocator);
    defer test_list.deinit();

    try expect(test_list.head == null);
    try expect(test_list.tail == null);
}

test "push and pop from back" {
    const allocator = std.heap.page_allocator;
    var test_list = try List(u8).init(allocator);
    defer test_list.deinit();

    // Test basic appending and ensure it changes length
    try expect(test_list.len == 0);
    try expect(test_list.empty());
    try test_list.append('H');
    try test_list.append('e');
    try test_list.append('l');
    try test_list.append('l');
    try test_list.append('o');
    try expect(test_list.len == 5);

    // Test popping from the back, ensuring it doesn't break when empty
    try expect(test_list.tail != null);
    try expect(test_list.popTail() == 'o');
    try expect(test_list.popTail() == 'l');
    try expect(test_list.popTail() == 'l');
    try expect(test_list.popTail() == 'e');
    try expect(test_list.popTail() == 'H');
    try expect(test_list.popTail() == null);

    try expect(test_list.head == null);
    try expect(test_list.tail == null);
    try expect(test_list.len == 0);
}

test "push and pop from front" {
    const allocator = std.heap.page_allocator;
    var test_list = try List(u8).init(allocator);
    defer test_list.deinit();

    // Test basic prepending and ensure it changes length
    try test_list.prepend('H');
    try test_list.prepend('e');
    try test_list.prepend('l');
    try test_list.prepend('l');
    try test_list.prepend('o');
    try expect(test_list.len == 5);

    // Test popping from the back, ensuring it doesn't break when empty
    try expect(test_list.head != null);
    try expect(test_list.popHead() == 'o');
    try expect(test_list.popHead() == 'l');
    try expect(test_list.popHead() == 'l');
    try expect(test_list.popHead() == 'e');
    try expect(test_list.popHead() == 'H');
    try expect(test_list.popHead() == null);

    try expect(test_list.head == null);
    try expect(test_list.tail == null);
    try expect(test_list.len == 0);
}

test "prepend and append together" {
    const allocator = std.heap.page_allocator;
    var test_list = try List(u8).init(allocator);
    defer test_list.deinit();

    // Push characters to the front and back
    try test_list.prepend('H');
    try test_list.append('e');
    try test_list.prepend('l');
    try test_list.append('l');
    try test_list.prepend('o');
    try test_list.append('!');

    // Check the head and tail
    try expect(test_list.head != null);
    try expect(test_list.peekHead() == 'o');

    try expect(test_list.tail != null);
    try expect(test_list.peekTail() == '!');

    // Pop characters from front and back
    _ = test_list.popTail();
    try expect(test_list.peekTail() == 'l');

    _ = test_list.popHead();
    try expect(test_list.popHead() == 'l');
}

test "iterator traversal" {
    const allocator = std.heap.page_allocator;
    var test_list = try List(u8).init(allocator);
    defer test_list.deinit();

    // Push characters to the test_list
    try test_list.append('H');
    try test_list.append('e');
    try test_list.append('l');
    try test_list.append('l');
    try test_list.append('o');

    // Create an iterator and traverse
    var it = test_list.begin();
    try expect(it.next().?.* == 'H');
    try expect(it.next().?.* == 'e');
    try expect(it.prev().?.* == 'l');
    try expect(it.next().?.* == 'e');
    try expect(it.next().?.* == 'l');
    try expect(it.next().?.* == 'l');
    try expect(it.next().?.* == 'o');

    // Check that no more elements exist
    try expect(it.next() == null);
}

test "get" {
    const allocator = std.heap.page_allocator;
    var list = try List(u8).init(allocator);
    defer list.deinit();

    try list.append('A');
    try list.append('B');
    try list.append('C');
    try list.append('D');
    try list.append('E');

    try std.testing.expectEqual(@as(u8, 'A'), (try list.get(0)));
    try std.testing.expectEqual(@as(u8, 'C'), (try list.get(2)));
    try std.testing.expectEqual(@as(u8, 'E'), (try list.get(4)));
}

test "remove and discard" {
    const allocator = std.heap.page_allocator;
    var list = try List(u8).init(allocator);
    defer list.deinit();

    try list.append('A');
    try list.append('B');
    try list.append('C');
    try list.append('D');
    try list.append('E');

    // Remove from middle
    try list.discard(2); // Remove 'C'
    try std.testing.expectEqual(@as(usize, 4), list.len);
    try std.testing.expectEqual(@as(u8, 'D'), (try list.get(2)));

    // Remove head
    try list.discard(0); // Remove 'A'
    try std.testing.expectEqual(@as(u8, 'B'), (try list.get(0)));

    // Remove tail
    try list.discard(2); // Remove 'E'
    try std.testing.expectEqual(@as(u8, 'D'), (try list.get(1)));
    try std.testing.expect(list.tail.?.*.value == 'D');

    // Try removing until empty
    try list.discard(0); // B
    try list.discard(0); // D
    try std.testing.expect(list.empty());
    try std.testing.expect(list.head == null);
    try std.testing.expect(list.tail == null);
}

test "insert elements at various positions" {
    const allocator = std.heap.page_allocator;
    var list = try List(u8).init(allocator);
    defer list.deinit();

    // Insert into empty list at index 0
    try list.insert(0, 'A');
    try std.testing.expectEqual(@as(usize, 1), list.len);
    try std.testing.expectEqual(@as(u8, 'A'), (try list.get(0)));

    // Insert at the beginning
    try list.insert(0, 'B'); // List: B, A
    try std.testing.expectEqual(@as(u8, 'B'), (try list.get(0)));
    try std.testing.expectEqual(@as(u8, 'A'), (try list.get(1)));

    // Insert at the end
    try list.insert(2, 'C'); // List: B, A, C
    try std.testing.expectEqual(@as(u8, 'C'), (try list.get(2)));

    // Insert in the middle
    try list.insert(1, 'D'); // List: B, D, A, C
    try std.testing.expectEqual(@as(u8, 'D'), (try list.get(1)));
    try std.testing.expectEqual(@as(u8, 'A'), (try list.get(2)));

    // Final check of all values
    const expected: [4]u8 = .{ 'B', 'D', 'A', 'C' };
    var i: usize = 0;
    while (i < expected.len) : (i += 1) {
        try std.testing.expectEqual(expected[i], (try list.get(i)));
    }
}
