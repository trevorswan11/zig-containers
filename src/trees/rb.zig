const std = @import("std");

const RED: u8 = 0;
const BLACK: u8 = 1;

const rbtraversal = enum {
    PREORDER,
    POSTORDER,
    INORDER,
};

pub fn RBTree(comptime T: type, comptime less: fn(a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        root: ?*Node = null,
        nil: *Node,
        min: ?*Node = null,

        allocator: *std.mem.Allocator,

        pub const Node = struct {
            data: T,
            color: u8,

            left: ?*Node,
            right: ?*Node,
            parent: ?*Node,

            pub fn init(value: T) Node {
                return Node{
                    .data = value,
                };
            }
        };

        fn first(self: *Self) ?*Node {
            if (self.root) |r| {
                return if (r.left != null) r.left else null;
            }
        }

        fn isEmpty(self: *Self) bool {
            if (self.root) |r| {
                return r.left == self.nil and r.right == self.nil;
            }
            return true;
        }

        pub fn init(allocator: *std.mem.Allocator) !Self {
            var nil_node = try allocator.create(Node);
            nil_node.* = Node{
                .left = undefined,
                .right = undefined,
                .parent = undefined,
                .data = undefined,
                .color = BLACK,
            };

            nil_node.left = nil_node;
            nil_node.right = nil_node;
            nil_node.parent = nil_node;

            return Self{
                .root = null,
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

        fn deinitNode(self: *Self, node: ?*Node) void {
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

        pub fn find(self: *Self, data: T) ?*Node {
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
        
        pub fn successor(self: *Self, node: *Node) ?*Node {
            if (node.right != self.nil) {
                // Case 1: Go right once, then all the way left
                var p = node.right;
                while (p.?.left != self.nil) {
                    p = p.?.left;
                }
                return p;
            } else {
                // Case 2: Go up until we are no longer a right child
                var p = node.parent;
                var n = node;
                while (p != null and n == p.?.right) {
                    n = p.?;
                    p = p.?.parent;
                }
                return p;
            }
        }
    };
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

