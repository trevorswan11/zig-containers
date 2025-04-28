const std = @import("std");

const RED: u8 = 0;
const BLACK: u8 = 1;

const TraversalOrder = enum {
    PREORDER,
    POSTORDER,
    INORDER,
};

pub fn RBTree(comptime T: type, comptime less: fn(a: T, b: T) bool) type {
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
                @panic("Cannot insert duplicate value!");
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
                    } else unreachable;
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
            while (current.parent.color == RED) {
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


    };
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

test "RBT (de)initialization and insertion" {
    const allocator = std.heap.page_allocator;
    var rbt = try RBTree(i32, lessThanInt).init(allocator);
    defer rbt.deinit();

    _ = try rbt.insert(1);
    _ = try rbt.insert(2);
    _ = try rbt.insert(3);
    _ = try rbt.insert(6);
}
