const std = @import("std");

pub fn AVLTree(comptime T: type, comptime less: fn(a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        root: ?*Node = null,
        allocator: *std.mem.Allocator,

        pub const Node = struct {
            data: T,
            left: ?*Node = null,
            right: ?*Node = null,
            height: usize = 0,

            pub fn init(value: T) Node {
                return Node{
                    .data = value,
                };
            }
        };

        pub fn init(allocator: *std.mem.Allocator) Self {
            return Self{
                .root = null,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.root) |node| {
                self.deinitNode(node);
            }
            self.root = null;
        }

        fn deinitNode(self: *Self, node: ?*Node) void {
            // perform a post-order traversal to safely free all nodes
            if (node) |n| {
                self.deinitNode(n.left);
                self.deinitNode(n.right);
                self.allocator.destroy(n);
            }
        }

        fn height(node: ?*Node) usize {
            return if (node) |n| n.height else 0;
        }

        fn getBalance(node: ?*Node) i32 {
            if (node == null) {
                return 0;
            }
            return @as(i32, @intCast(height(node.?.right))) - @as(i32, @intCast(height(node.?.left)));
        }

        fn rightRotate(y: ?*Node) ?*Node {
            if (y) |n| {
                const x = n.left.?;
                const temp = x.right;

                x.right = n;
                n.left = temp;

                n.height = @max(height(n.left), height(n.right)) + 1;
                x.height = @max(height(x.left), height(x.right)) + 1;

                return x;
            }
            return null;
        }

        fn leftRotate(x: ?*Node) ?*Node {
            if (x) |n| {
                const y = n.right.?;
                const temp = y.left;

                y.left = n;
                n.right = temp;

                y.height = @max(height(y.left), height(y.right)) + 1;
                n.height = @max(height(n.left), height(n.right)) + 1;

                return y;
            }
            return null;
        }

        fn leftRightRotate(z: ?*Node) ?*Node {
            z.?.left = leftRotate(z.?.left);
            return rightRotate(z);
        }

        fn rightLeftRotate(z: ?*Node) ?*Node {
            z.?.right = rightRotate(z.?.right);
            return leftRotate(z);
        }

        pub fn search(self: *Self, value: T) ?*Node {
            return searchImpl(self.root, value);
        }

        fn searchImpl(node: ?*Node, value: T) ?*Node {
            if (node) |n| {
                if (less(value, n.data)) {
                    return searchImpl(n.left, value);
                } else if (less(n.data, value)) {
                    return searchImpl(n.right, value);
                } else {
                    return node;
                }
            }
            return null;
        }

        pub fn insert(self: *Self, value: T) !void {
            if (self.search(value)) |_| {
                return error.DuplicateItem;
            }
            _ = try self.insertImpl(self.root, value);
        }

        // there will be memory leaks here, clean up later
        fn insertImpl(self: *Self, node: ?*Node, value: T) !?*Node {
            if (node == null) {
                const n = try self.allocator.create(Node);
                n.* = Node{ .data = value, };
                node.?.* = n.*;
            } else {
                if (less(value, node.?.data)) {
                    node.?.left = try self.insertImpl(node.?.left, value);
                } else if (less(node.?.data, value)) {
                    node.?.right = try self.insertImpl(node.?.right, value);
                } else unreachable;
            }

            node.?.height = @max(height(node.?.left), height(node.?.right)) + 1;
            const balance: i32 = getBalance(node); 

            if (balance >= 2) {
                if (less(value, node.?.right.?.data)) {
                    node.?.* = rightLeftRotate(node).?.*; 
                } else {
                    node.?.* = leftRotate(node).?.*;
                }
            } else if (balance <= -2){
                if (less(value, node.?.left.?.data)) {
                    node.?.* = rightRotate(node).?.*;
                } else {
                    node.?.* = leftRightRotate(node).?.*;
                }
            }   

            return node;
        }

        pub fn delete(self: *Self, value: T) !?*Node {
            if (self.search(value)) |to_delete| {
                defer self.allocator.destroy(to_delete);
                return self.deleteImpl(self.root, to_delete);
            }
            return null;
        }

        // there will be memory leaks here, clean up later
        fn deleteImpl(self: *Self, node: ?*Node, to_delete: ?*Node) ?*Node {
            if (node == null or to_delete == null) {
                return null;
            }

            if (less(to_delete.?.data, node.?.data)) {
                node.?.left = self.deleteImpl(node.?.left, to_delete);
            } else if (less(node.?.data, to_delete.?.data)) {
                node.?.right = self.deleteImpl(node.?.right, to_delete);
            } else {
                if (node.?.left != null and node.?.right != null) {
                    const minim = minImpl(node.?.right);
                    node.?.data = minim.?.data;
                    node.?.right = self.deleteImpl(node.?.right, minim);
                } else {
                    node = if (node.?.left != null) node.?.left else node.?.right;
                }
            }

            node.?.height = @max(height(node.?.left), height(node.?.right)) + 1;
            const balance: i32 = getBalance(node);
            var left_balance: i32 = 0;
            var right_balance: i32 = 0;
            if (node.?.left) |left| {
                left_balance = getBalance(left);
            }
            if (node.?.right) |right| {
                right_balance = getBalance(right);
            }

            if (balance >= 2) {
                if (right_balance >= 0) {
                    node.?.* = leftRotate(node).?.*;
                } else {
                    node.?.* = rightLeftRotate(node).?.*;
                }
            } else if (balance <= -2) {
                if (left_balance >= 0) {
                    node.?.* = rightRotate(node).?.*;
                } else {
                    node.?.* = leftRightRotate(node).?.*;
                }
            }

            return node;
        }

        pub fn inorder(self: *Self) void {
            std.debug.print("[ ", .{});
            inorderImpl(self.root);
            std.debug.print("]", .{});
        }

        fn inorderImpl(node: ?*Node) void {
            if (node) |n| {
                inorderImpl(n.left);
                std.debug.print("{} ", .{n.data});
                inorderImpl(n.right);
            }
        }

        pub fn verifyAVLInvariant(self: *Self) bool {
            return verifyAVLInvariantImpl(self.root);
        }

        fn verifyAVLInvariantImpl(node: ?*Node) bool {
            if (node == null) {
                return true;
            }

            const balance = getBalance(node);
            if (balance > 1 or balance < -1) {
                return false;
            }

            if (node.?.left != null) {
                if (!less(maxImpl(node.?.left).?.data, node.?.data)) {
                    return false;
                }
            }

            if (node.?.right != null) {
                if (!less(node.?.data, minImpl(node.?.right).?.data)) {
                    return false;
                }
            }

            return verifyAVLInvariantImpl(node.?.left) and verifyAVLInvariantImpl(node.?.right);
        }

        pub fn min(self: *Self) ?*Node {
            return min(self.root);
        }

        fn minImpl(node: ?*Node) ?*Node {
            if (node == null) {
                return null;
            } else if (node.?.left == null) {
                return node;
            }

            return minImpl(node.?.left);
        }

        pub fn max(self: *Self) ?*Node {
            return max(self.root);
        }

        fn maxImpl(node: ?*Node) ?*Node {
            if (node == null) {
                return null;
            } else if (node.?.right == null) {
                return node;
            }

            return maxImpl(node);
        }
    };
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

test "Insert integers and check inorder traversal" {
    var allocator = std.testing.allocator;
    var tree = AVLTree(i32, lessThanInt).init(&allocator);

    try tree.insert(10);
    try tree.insert(20);
    try tree.insert(30);
    try tree.insert(40);
    try tree.insert(50);
    try tree.insert(25);

    try std.testing.expect(tree.verifyAVLInvariant());
}

test "Insert sorted integers and check AVL balancing" {
    var allocator = std.testing.allocator;
    var tree = AVLTree(i32, lessThanInt).init(&allocator);

    // Insert sorted keys (worst case for BST)
    try tree.insert(1);
    try tree.insert(2);
    try tree.insert(3);
    try tree.insert(4);
    try tree.insert(5);
    try tree.insert(6);
    try tree.insert(7);

    // AVL tree should stay balanced
    try std.testing.expect(tree.verifyAVLInvariant());
}

test "Insert random integers and check AVL properties" {
    var allocator = std.testing.allocator;
    var tree = AVLTree(i32, lessThanInt).init(&allocator);

    const random_keys = [_]i32{45, 20, 70, 10, 30, 60, 80};

    for (random_keys) |key| {
        try tree.insert(key);
    }

    try std.testing.expect(tree.verifyAVLInvariant());
}

test "Insert duplicate keys" {
    var allocator = std.testing.allocator;
    var tree = AVLTree(i32, lessThanInt).init(&allocator);

    try tree.insert(10);
    try tree.insert(10); // Should NOT crash or duplicate

    try std.testing.expect(tree.verifyAVLInvariant());
}