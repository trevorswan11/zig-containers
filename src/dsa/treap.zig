const std = @import("std");
const hash_set = @import("hash_set.zig").HashSet;

const RANDOM_ITERATIONS = 20;

pub fn Treap(comptime T: type, comptime less: fn (a: T, b: T) bool, comptime eql: fn (a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        root: ?*Node,
        set: hash_set(u64, void),
        allocator: std.mem.Allocator,

        pub const Node = struct {
            key: T,
            priority: u64,
            left: ?*Node,
            right: ?*Node,

            pub fn create(allocator: std.mem.Allocator, key: T, priority: u64) !*Node {
                const node = try allocator.create(Node);
                node.* = Node{
                    .key = key,
                    .priority = priority,
                    .left = null,
                    .right = null,
                };
                return node;
            }
        };

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .root = null,
                .set = try hash_set(u64, void).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.deinitNode(self.root);
        }

        fn deinitNode(self: *Self, node: ?*Node) void {
            if (node) |n| {
                self.deinitNode(n.left);
                self.deinitNode(n.right);
                self.allocator.destroy(n);
            }
        }

        pub fn size(self: *Self) usize {
            return self.countNodes(self.root);
        }

        fn countNodes(self: *Self, node: ?*Node) usize {
            if (node == null) {
                return 0;
            }
            return 1 + self.countNodes(node.?.left) + self.countNodes(node.?.right);
        }

        pub fn height(self: *Self) usize {
            return self.heightImpl(self.root);
        }

        fn heightImpl(self: *Self, node: ?*Node) usize {
            if (node == null) {
                return 0;
            }
            const left_height = self.heightImpl(node.?.left);
            const right_height = self.heightImpl(node.?.right);
            return 1 + @max(left_height, right_height);
        }

        pub fn insert(self: *Self, key: T) !void {
            var priority = random_priority();
            var i: usize = 0;
            while (self.set.contains(priority)) : (i += 1) {
                if (i > RANDOM_ITERATIONS) {
                    break;
                }
                priority = random_priority();
            }
            if (self.set.contains(priority)) {
                return error.RandomIterationLimit;
            }
            try self.set.insert(priority);
            self.root = try self.insertImpl(self.root, key, priority);
        }

        fn insertImpl(self: *Self, node: ?*Node, key: T, priority: u64) !*Node {
            if (node == null) {
                return Node.create(self.allocator, key, priority);
            }

            if (less(key, node.?.key)) {
                node.?.left = try self.insertImpl(node.?.left, key, priority);
                if (node.?.left.?.priority > node.?.priority) {
                    return rotate_right(node.?);
                }
            } else {
                node.?.right = try self.insertImpl(node.?.right, key, priority);
                if (node.?.right.?.priority > node.?.priority) {
                    return rotate_left(node.?);
                }
            }
            return node.?;
        }

        fn rotate_right(y: *Node) *Node {
            const x = y.left.?;
            y.left = x.right;
            x.right = y;
            return x;
        }

        fn rotate_left(x: *Node) *Node {
            const y = x.right.?;
            x.right = y.left;
            y.left = x;
            return y;
        }

        fn random_priority() u64 {
            return std.crypto.random.int(u64);
        }

        pub fn contains(self: *Self, key: T) bool {
            var current = self.root;
            while (current) |node| {
                if (eql(key, node.key)) {
                    return true;
                }
                if (less(key, node.key)) {
                    current = node.left;
                } else {
                    current = node.right;
                }
            }
            return false;
        }

        pub fn findMin(self: *Self) ?T {
            var current = self.root;
            while (current) |node| {
                if (node.left == null) {
                    return node.key;
                }
                current = node.left;
            }
            return null;
        }

        pub fn findMax(self: *Self) ?T {
            var current = self.root;
            while (current) |node| {
                if (node.right == null) {
                    return node.key;
                }
                current = node.right;
            }
            return null;
        }

        pub fn remove(self: *Self, key: T) !void {
            self.root = try self.removeImpl(self.root, key);
        }

        fn removeImpl(self: *Self, node: ?*Node, key: T) !?*Node {
            if (node == null) return null;

            if (less(key, node.?.key)) {
                node.?.left = try self.removeImpl(node.?.left, key);
            } else if (less(node.?.key, key)) {
                node.?.right = try self.removeImpl(node.?.right, key);
            } else {
                const left = node.?.left;
                const right = node.?.right;

                if (left == null and right == null) {
                    self.allocator.destroy(node.?);
                    return null;
                }

                if (left == null) {
                    const ret = right;
                    self.allocator.destroy(node.?);
                    return ret;
                }

                if (right == null) {
                    const ret = left;
                    self.allocator.destroy(node.?);
                    return ret;
                }

                if (left.?.priority > right.?.priority) {
                    const new_root = rotate_right(node.?);
                    new_root.right = try self.removeImpl(new_root.right, key);
                    return new_root;
                } else {
                    const new_root = rotate_left(node.?);
                    new_root.left = try self.removeImpl(new_root.left, key);
                    return new_root;
                }
            }
            _ = self.set.remove(node.?.priority);
            return node;
        }

        pub fn clear(self: *Self) void {
            self.deinit();
            self.root = null;
        }

        pub fn inorder(self: *Self) void {
            self.inorderImpl(self.root);
        }

        fn inorderImpl(self: *Self, node: ?*Node) void {
            if (node) |n| {
                self.inorderImpl(n.left);
                std.debug.print("key: {}, priority: {}\n", .{ n.key, n.priority });
                self.inorderImpl(n.right);
            }
        }

        pub fn print(self: *Self) void {
            std.debug.print("\n", .{});
            self.printImpl(self.root, 0);
        }

        fn printImpl(self: *Self, node: ?*Node, level: usize) void {
            if (node) |n| {
                self.printImpl(n.right, level + 1);

                const temp = "    ";
                const indentArray: []const []const u8 = &[_][]const u8{
                    temp[0..1],
                    temp[1..2],
                    temp[2..3],
                    temp[3..4],
                };

                const indent = std.mem.join(self.allocator, "", indentArray) catch return;
                std.debug.print("{s}key: {}, priority: {}\n", .{ indent, n.key, n.priority });

                self.printImpl(n.left, level + 1);
            }
        }

        pub fn preorder(self: *Self) ![]const u8 {
            var buffer = std.ArrayList(u8).init(self.allocator);
            defer buffer.deinit();
            const writer = buffer.writer().any();
            try self.preorderImpl(self.root, writer);
            return buffer.toOwnedSlice();
        }

        fn preorderImpl(self: *Self, node: ?*Node, writer: std.io.AnyWriter) !void {
            if (node) |n| {
                try self.preorderImpl(n.left);
                try writer.print("key: {}, priority: {}\n", .{ n.key, n.priority });
                try self.preorderImpl(n.right);
            }
        }

        pub fn toString(self: *Self) ![]const u8 {
            return try preorder(self);
        }
    };
}

fn eqlInt(a: i32, b: i32) bool {
    return a == b;
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

test "Treap insert and in-order traversal" {
    const allocator = std.heap.page_allocator;
    var treap = Treap(i32, lessThanInt, eqlInt).init(allocator);
    defer treap.deinit();

    try treap.insert(5);
    try treap.insert(2);
    try treap.insert(8);
    try treap.insert(1);
    try treap.insert(3);
}

test "Treap basic operations" {
    const allocator = std.heap.page_allocator;
    var treap = Treap(i32, lessThanInt, eqlInt).init(allocator);
    defer treap.deinit();

    // Insert
    try treap.insert(10);
    try treap.insert(20);
    try treap.insert(5);
    try treap.insert(15);
    try treap.insert(25);

    // Contains
    try std.testing.expect(treap.contains(10));
    try std.testing.expect(treap.contains(5));
    try std.testing.expect(!treap.contains(99));

    // Size
    try std.testing.expectEqual(@as(usize, 5), treap.size());

    // Height (we accept height >= 1 since priority is random)
    try std.testing.expect(treap.height() >= 1);

    // Min/Max
    try std.testing.expectEqual(@as(i32, 5), treap.findMin().?);
    try std.testing.expectEqual(@as(i32, 25), treap.findMax().?);
}

test "Treap remove node and check integrity" {
    const allocator = std.heap.page_allocator;
    var treap = Treap(i32, lessThanInt, eqlInt).init(allocator);
    defer treap.deinit();

    try treap.insert(50);
    try treap.insert(30);
    try treap.insert(70);
    try treap.insert(20);
    try treap.insert(40);
    try treap.insert(60);
    try treap.insert(80);

    try std.testing.expectEqual(@as(usize, 7), treap.size());
    try std.testing.expect(treap.contains(30));

    try treap.remove(30);
    try std.testing.expect(!treap.contains(30));
    try std.testing.expectEqual(@as(usize, 6), treap.size());

    try treap.remove(50);
    try std.testing.expect(!treap.contains(50));
    try std.testing.expectEqual(@as(usize, 5), treap.size());
}

test "Treap clear and reuse" {
    const allocator = std.heap.page_allocator;
    var treap = Treap(i32, lessThanInt, eqlInt).init(allocator);
    defer treap.deinit();

    try treap.insert(100);
    try treap.insert(200);
    try treap.insert(300);

    try std.testing.expectEqual(@as(usize, 3), treap.size());

    treap.clear();
    try std.testing.expectEqual(@as(usize, 0), treap.size());
    try std.testing.expect(!treap.contains(100));

    try treap.insert(42);
    try std.testing.expect(treap.contains(42));
}

test "Treap stress test: insert, contains, remove, size" {
    const allocator = std.heap.page_allocator;
    var treap = Treap(i32, lessThanInt, eqlInt).init(allocator);
    defer treap.deinit();

    const num_elements = 10_000;
    var inserted = std.AutoHashMap(i32, void).init(allocator);
    defer inserted.deinit();

    // Insert random elements
    var i: usize = 0;
    while (i < num_elements) : (i += 1) {
        const value = std.crypto.random.int(i32);
        if (!inserted.contains(value)) {
            try treap.insert(value);
            try inserted.put(value, {});
        }
    }

    // Check size is correct
    try std.testing.expectEqual(inserted.count(), treap.size());

    // Check all inserted values are in the treap
    var iter = inserted.iterator();
    while (iter.next()) |entry| {
        try std.testing.expect(treap.contains(entry.key_ptr.*));
    }

    // Remove half the elements
    var removed: u64 = 0;
    iter = inserted.iterator();
    while (iter.next()) |entry| {
        if (removed >= num_elements / 2) break;
        try treap.remove(entry.key_ptr.*);
        removed += 1;
    }

    // Size should now be ~half
    try std.testing.expect(treap.size() <= num_elements / 2 + 10); // +10 for collisions/repeat inserts
}
