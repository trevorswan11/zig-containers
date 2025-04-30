const std = @import("std");

const RED: u8 = 0;
const BLACK: u8 = 1;

const TraversalOrder = enum {
    PREORDER,
    POSTORDER,
    INORDER,
};

pub fn RBTree(comptime T: type, comptime less: fn (a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        root: ?*RBNode = null,
        nil: *RBNode,
        min: ?*RBNode = null,

        allocator: std.mem.Allocator,

        pub const RBNode = struct {
            data: T,
            color: u8,

            left: *RBNode,
            right: *RBNode,
            parent: *RBNode,
        };

        fn first(self: *Self) ?*RBNode {
            if (self.root) |r| {
                return r.left;
            }
            return null;
        }

        fn isEmpty(self: *Self) bool {
            if (self.root) |r| {
                return r.left == self.nil and r.right == self.nil;
            }
            return true;
        }

        pub fn init(allocator: std.mem.Allocator) !Self {
            var nil_node = try allocator.create(RBNode);
            nil_node.* = RBNode{
                .left = undefined,
                .right = undefined,
                .parent = undefined,
                .data = undefined,
                .color = BLACK,
            };

            nil_node.left = nil_node;
            nil_node.right = nil_node;
            nil_node.parent = nil_node;

            const root_node = try allocator.create(RBNode);
            root_node.* = RBNode{
                .left = nil_node,
                .right = nil_node,
                .parent = nil_node,
                .color = BLACK,
                .data = undefined,
            };

            return Self{
                .root = root_node,
                .nil = nil_node,
                .min = null,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            if (self.root) |node| {
                self.deinitNode(node);
            }
            self.root = null;
        }

        fn deinitNode(self: *Self, node: ?*RBNode) void {
            // perform a post-order traversal to safely free all nodes
            if (node) |n| {
                if (n == self.nil) {
                    return;
                }
                self.deinitNode(n.left);
                self.deinitNode(n.right);
                self.allocator.destroy(n);
            }
        }

        pub fn find(self: *Self, data: T) ?*RBNode {
            var p = self.first();
            while (p) |ptr| {
                if (ptr == self.nil) {
                    break;
                }
                if (less(data, ptr.data)) {
                    p = ptr.left;
                } else if (less(ptr.data, data)) {
                    p = ptr.right;
                } else {
                    return p;
                }
            }
            return null;
        }

        pub fn successor(self: *Self, node: *RBNode) *RBNode {
            if (node.right != self.nil) {
                // Case 1: Go right once, then all the way left
                var p = node.right;
                while (p.left != self.nil) : (p = p.left) {}
                return p;
            } else {
                // Case 2: Go up until we are no longer a right child
                var p = node.parent;
                var n = node;
                while (n == p.right) {
                    n = p;
                    p = p.parent;
                }
                return p;
            }
        }

        pub fn apply(
            self: *Self,
            node: *RBNode,
            func: fn (data: *anyopaque, cookie: *anyopaque) anyerror!void,
            cookie: *anyopaque,
            order: TraversalOrder,
        ) anyerror!void {
            if (node == self.nil) {
                return;
            }

            if (order == .Preorder) {
                try func(node.data, cookie);
            }
            try self.apply(node.left, func, cookie, order);

            if (order == .Inorder) {
                try func(node.data, cookie);
            }
            try self.apply(node.right, func, cookie, order);

            if (order == .Postorder) {
                try func(node.data, cookie);
            }
        }

        pub fn rotateLeft(self: *Self, x: *RBNode) void {
            var y = x.right;
            x.right = y.left;
            if (x.right != self.nil) {
                x.right.parent = x;
            }

            y.parent = x.parent;
            if (x == x.parent.left) {
                x.parent.left = y;
            } else {
                x.parent.right = y;
            }

            y.left = x;
            x.parent = y;
        }

        pub fn rotateRight(self: *Self, x: *RBNode) void {
            var y = x.left;
            x.left = y.right;
            if (x.left != self.nil) {
                x.left.parent = x;
            }

            y.parent = x.parent;
            if (x == x.parent.left) {
                x.parent.left = y;
            } else {
                x.parent.right = y;
            }

            y.right = x;
            x.parent = y;
        }

        pub fn insert(self: *Self, data: T) !?*RBNode {
            if (self.find(data)) |_| {
                return error.DuplicateItem;
            }

            var current = self.first();
            var parent = if (self.root == null) self.nil else self.root.?;

            while (current != null) {
                if (current.? == self.nil) {
                    break;
                }

                if (current) |c| {
                    parent = c;
                    if (less(data, c.data)) {
                        current.? = c.left;
                    } else if (less(c.data, data)) {
                        current.? = c.right;
                    } else {
                        return error.DuplicateItem;
                    }
                }
            }

            var real_current = try self.allocator.create(RBNode);
            const new_node = real_current;

            real_current.left = self.nil;
            real_current.right = self.nil;
            real_current.parent = parent;
            real_current.color = RED;
            real_current.data = data;

            if (parent == self.nil or less(data, parent.data)) {
                parent.left = real_current;
            } else {
                parent.right = real_current;
            }

            if (self.min == null or less(real_current.data, self.min.?.data)) {
                self.min = real_current;
            }

            //
            // insertion into a red-black tree:
            // 0-children root cluster (parent node is BLACK) becomes 2-children root cluster (new root node)
            //   paint root node BLACK, and done
            // 2-children cluster (parent node is BLACK) becomes 3-children cluster
            //   done
            // 3-children cluster (parent node is BLACK) becomes 4-children cluster
            //   done
            // 3-children cluster (parent node is RED) becomes 4-children cluster
            //   rotate, and done
            // 4-children cluster (parent node is RED) splits into 2-children cluster and 3-children cluster
            //   split, and insert grandparent node into parent cluster
            //
            if (real_current.parent.color == RED) {
                // insertion into 3-children cluster (parent node is RED)
                // insertion into 4-children cluster (parent node is RED)
                self.insertRepair(real_current);
            } else {
                // insertion into 0-children root cluster (parent node is BLACK)
                // insertion into 2-children cluster (parent node is BLACK)
                // insertion into 3-children cluster (parent node is BLACK)
            }

            // the root is always BLACK
            self.first().?.color = BLACK;
            return new_node;
        }

        fn insertRepair(self: *Self, current_: *RBNode) void {
            var current = current_;
            var uncle: *RBNode = undefined;
            var flag = true; // simulates a do while loop
            while (flag or current.parent.color == RED) {
                flag = false;
                if (current.parent == current.parent.parent.left) {
                    uncle = current.parent.parent.right;
                    if (uncle.color == RED) {
                        // insertion into 4-children cluster
                        current.parent.color = BLACK;
                        uncle.color = BLACK;
                        current = current.parent.parent;
                        current.color = RED;
                    } else {
                        // insertion into 3-children cluster
                        if (current == current.parent.right) {
                            current = current.parent;
                            self.rotateLeft(current);
                        }

                        current.parent.color = BLACK;
                        current.parent.parent.color = RED;
                        self.rotateRight(current.parent.parent);
                    }
                } else {
                    uncle = current.parent.parent.left;
                    if (uncle.color == RED) {
                        // insertion into 4-children cluster
                        current.parent.color = BLACK;
                        uncle.color = BLACK;
                        current = current.parent.parent;
                        current.color = RED;
                    } else {
                        // insertion into 3-children cluster
                        if (current == current.parent.left) {
                            current = current.parent;
                            self.rotateRight(current);
                        }

                        current.parent.color = BLACK;
                        current.parent.parent.color = RED;
                        self.rotateLeft(current.parent.parent);
                    }
                }
            }
        }

        pub fn delete(self: *Self, data: T) ?T {
            var node: *RBNode = undefined;
            if (self.find(data)) |found| {
                node = found;
            } else {
                return null;
            }

            var target: *RBNode = undefined;
            var child: *RBNode = undefined;

            if (node.left == self.nil or node.right == self.nil) {
                target = node;
                if (self.min != null and self.min.? == target) {
                    self.min.? = self.successor(node);
                }
            } else {
                target = self.successor(node);
                node.data = target.data;
            }
            child = if (target.left == self.nil) target.right else target.left;

            //
            // deletion from red-black tree
            //   4-children cluster (RED target node) becomes 3-children cluster
            //     done
            //   3-children cluster (RED target node) becomes 2-children cluster
            //     done
            //   3-children cluster (BLACK target node, RED child node) becomes 2-children cluster
            //     paint child node BLACK, and done
            //
            //   2-children root cluster (BLACK target node, BLACK child node) becomes 0-children root cluster
            //     done
            //
            //   2-children cluster (BLACK target node, 4-children sibling cluster) becomes 3-children cluster
            //     transfer, and done
            //   2-children cluster (BLACK target node, 3-children sibling cluster) becomes 2-children cluster
            //     transfer, and done
            //
            //   2-children cluster (BLACK target node, 2-children sibling cluster, 3/4-children parent cluster) becomes 3-children cluster
            //     fuse, paint parent node BLACK, and done
            //   2-children cluster (BLACK target node, 2-children sibling cluster, 2-children parent cluster) becomes 3-children cluster
            //     fuse, and delete parent node from parent cluster
            //
            if (target.color == BLACK) {
                if (child.color == RED) {
                    // deletion from 3-children cluster (BLACK target node, RED child node)
                    child.color = BLACK;
                } else if (self.first() != null and target == self.first().?) {
                    // deletion from 2-children root cluster (BLACK target node, BLACK child node)
                } else {
                    // deletion from 2-children cluster (BLACK target node, ...)
                    self.deleteRepair(target);
                }
            } else {
                // deletion from 4-children cluster (RED target node)
                // deletion from 3-children cluster (RED target node)
            }

            if (child != self.nil) {
                child.parent = target.parent;
            }

            if (target == target.parent.left) {
                target.parent.left = child;
            } else {
                target.parent.right = child;
            }

            self.allocator.destroy(target);
            return data;
        }

        fn deleteRepair(self: *Self, current_: *RBNode) void {
            var current = current_;
            var sibling: *RBNode = undefined;
            var flag = true;
            while (flag or (self.first() != null and current != self.first())) {
                flag = false;
                if (current == current.parent.left) {
                    sibling = current.parent.right;

                    if (sibling.color == RED) {
                        sibling.color = BLACK;
                        current.parent.color = RED;
                        self.rotateLeft(current.parent);
                        sibling = current.parent.right;
                    }

                    if (sibling.right.color == BLACK and sibling.left.color == BLACK) {
                        // 2-children sibling cluster, fuse by recoloring
                        sibling.color = RED;
                        if (current.parent.color == RED) {
                            current.parent.color = BLACK;
                            break;
                        } else {
                            current = current.parent;
                        }
                    } else {
                        // 3/4-children sibling cluster, perform an adjustment
                        if (sibling.right.color == BLACK) {
                            sibling.left.color = BLACK;
                            sibling.color = RED;
                            self.rotateRight(sibling);
                            sibling = current.parent.right;
                        }

                        // transfer by rotation and recoloring
                        sibling.color = current.parent.color;
                        current.parent.color = BLACK;
                        sibling.right.color = BLACK;
                        self.rotateLeft(current.parent);
                        break;
                    }
                } else {
                    sibling = current.parent.left;

                    if (sibling.color == RED) {
                        sibling.color = BLACK;
                        current.parent.color = RED;
                        self.rotateRight(current.parent);
                        sibling = current.parent.left;
                    }

                    if (sibling.right.color == BLACK and sibling.left.color == BLACK) {
                        // 2-children sibling cluster, fuse by recoloring
                        sibling.color = RED;
                        if (current.parent.color == RED) {
                            current.parent.color = BLACK;
                            break;
                        } else {
                            current = current.parent;
                        }
                    } else {
                        // 3/4-children sibling cluster, perform an adjustment
                        if (sibling.left.color == BLACK) {
                            sibling.right.color = BLACK;
                            sibling.color = RED;
                            self.rotateRight(current.parent);
                            break;
                        }

                        // transfer by rotation and recoloring
                        sibling.color = current.parent.color;
                        current.parent.color = BLACK;
                        sibling.left.color = BLACK;
                        self.rotateRight(current.parent);
                        break;
                    }
                }
            }
        }

        fn checkInvariants(self: *Self) !void {
            if (self.root != null) {
                try self.assertBlackRoot();
                try self.assertNoRedRed(self.root);
                _ = try self.countBlackHeight(self.root);
            }
        }

        fn assertBlackRoot(self: *Self) !void {
            if (self.root.?.color != BLACK)
                return error.RootNotBlack;
        }

        fn assertNoRedRed(self: *Self, node: ?*RBNode) !void {
            if (node == null or node.? == self.nil) return;

            if (node.?.color == RED) {
                if (node.?.left != self.nil and node.?.left.color == RED)
                    return error.RedViolation;
                if (node.?.right != self.nil and node.?.right.color == RED)
                    return error.RedViolation;
            }

            try self.assertNoRedRed(node.?.left);
            try self.assertNoRedRed(node.?.right);
        }

        fn countBlackHeight(self: *Self, node: ?*RBNode) !usize {
            if (node == null or node.? == self.nil) return 1;

            const left_height = try self.countBlackHeight(node.?.left);
            const right_height = try self.countBlackHeight(node.?.right);

            if (left_height != right_height)
                return error.BlackHeightMismatch;

            const is_black = node.?.color == BLACK;
            return left_height + @intFromBool(is_black);
        }
    };
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

const testing = std.testing;
const expect = testing.expect;

test "RBT (de)initialization and insertion" {
    const allocator = std.heap.page_allocator;
    var rbt = try RBTree(i32, lessThanInt).init(allocator);
    defer rbt.deinit();

    _ = try rbt.insert(1);
    try rbt.checkInvariants();
    _ = try rbt.insert(2);
    _ = try rbt.insert(3);
    _ = try rbt.insert(6);
}

test "RBT deletion" {
    const allocator = std.heap.page_allocator;
    var rbt = try RBTree(i32, lessThanInt).init(allocator);
    defer rbt.deinit();

    _ = try rbt.insert(1);
    _ = try rbt.insert(2);
    _ = try rbt.insert(3);
    _ = try rbt.insert(6);

    _ = rbt.delete(2);
    _ = rbt.delete(7);
}

test "RBTree basic insert, find, and delete" {
    const allocator = std.heap.page_allocator;
    var tree = try RBTree(i32, lessThanInt).init(allocator);
    defer tree.deinit();

    // Insert elements
    _ = try tree.insert(10);
    _ = try tree.insert(5);
    _ = try tree.insert(20);

    // Verify structure
    const node_10 = tree.find(10);
    const node_5 = tree.find(5);
    const node_20 = tree.find(20);

    try expect(node_10 != null);
    try expect(node_5 != null);
    try expect(node_20 != null);

    try expect(node_10.?.data == 10);
    try expect(node_5.?.data == 5);
    try expect(node_20.?.data == 20);

    // Find a non-existent element
    const node_99 = tree.find(99);
    try expect(node_99 == null);

    // Delete an element
    const deleted = tree.delete(5);
    try expect(deleted != null);
    try expect(deleted.? == 5);

    const node_5_after = tree.find(5);
    try expect(node_5_after == null);
}

test "RBTree duplicate insert should panic" {
    const allocator = std.heap.page_allocator;
    var tree = try RBTree(i32, lessThanInt).init(allocator);
    defer tree.deinit();

    _ = try tree.insert(42);

    // This should panic due to duplicate insert
    try std.testing.expectError(error.DuplicateItem, tree.insert(42));
}

test "RBTree min node tracking" {
    const allocator = std.heap.page_allocator;
    var tree = try RBTree(i32, lessThanInt).init(allocator);
    defer tree.deinit();

    _ = try tree.insert(30);
    _ = try tree.insert(10);
    _ = try tree.insert(50);

    try expect(tree.min != null);
    try expect(tree.min.?.data == 10);

    // Delete the current minimum
    _ = tree.delete(10);
    try expect(tree.min != null);
    try expect(tree.min.?.data == 30);
}
