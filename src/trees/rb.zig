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

        fn first(self: *Self) ?Node {
            if (self.root) |r| {
                return if (r.left.? != null) r.left else null;
            }
        }

        fn isEmpty(self: *Self) bool {
            if (self.root) |r| {
                return r.left == self.nil and r.right == self.nil;
            }
            return true;
        }

        pub fn init(allocator: *std.mem.Allocator) !Self {
            var rbt = try allocator.create(Self);
            rbt.* = Self{
                .root = null,
                .nil = try allocator.create(Node),
                .min = null,
                .allocator = allocator,
            };

            rbt.nil.?
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
    };
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

