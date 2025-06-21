const std = @import("std");
const hash_map = @import("hash_map.zig").HashMap;
const array = @import("array.zig").Array;

const DEFAULT_LIST_SIZE: usize = 7;

pub fn AdjacencyList(comptime T: type, Ctx: type) type {
    return struct {
        const Self = @This();

        map: hash_map(T, array(T), Ctx),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .map = try hash_map(T, array(T), Ctx).init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.map.map.valueIterator();
            while (it.next()) |list| {
                list.*.deinit();
            }
            self.map.deinit();
        }

        pub fn put(self: *Self, node: T) !void {
            if (self.containsNode(node)) {
                return;
            }
            try self.map.put(node, try array(T).init(self.allocator, DEFAULT_LIST_SIZE));
        }

        pub fn addEdge(self: *Self, from: T, to: T) !void {
            const entry = try self.map.map.getOrPut(from);
            if (!entry.found_existing) {
                entry.value_ptr.* = try array(T).init(self.allocator, DEFAULT_LIST_SIZE);
            }
            try entry.value_ptr.*.push(to);
        }

        pub fn getNeighbors(self: *Self, node: T) ?array(T) {
            const found = self.map.find(node);
            return if (found) |list| list else null;
        }

        pub fn containsNode(self: *AdjacencyList(T, Ctx), node: T) bool {
            return self.map.containsKey(node);
        }

        pub fn clear(self: *AdjacencyList(T, Ctx)) void {
            var it = self.map.map.valueIterator();
            while (it.next()) |list| {
                list.clear();
            }
            self.map.clear();
        }

        pub fn size(self: *AdjacencyList(T, Ctx)) usize {
            return self.map.size();
        }

        pub fn print(self: *Self) void {
            var it = self.map.map.iterator();
            while (it.next()) |entry| {
                std.debug.print("{}: ", .{entry.key_ptr.*});
                for (entry.value_ptr.*.arr) |neighbor| {
                    std.debug.print("{} ", .{neighbor});
                }
                std.debug.print("\n", .{});
            }
        }

        pub fn toString(self: *Self) ![]const u8 {
            var buffer = std.ArrayList(u8).init(self.allocator);
            defer buffer.deinit();
            const writer = buffer.writer();

            var it = self.map.map.iterator();
            while (it.next()) |entry| {
                try writer.print("{}: ", .{entry.key_ptr.*});
                for (entry.value_ptr.*.arr) |neighbor| {
                    try writer.print("{} ", .{neighbor});
                }
                try writer.print("\n", .{});
            }
            _ = buffer.pop();

            return try buffer.toOwnedSlice();
        }
    };
}

const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "add and check neighbors" {
    const allocator = std.heap.page_allocator;
    var graph = AdjacencyList(u32, void).init(allocator);
    defer graph.deinit();

    try graph.addEdge(1, 2);
    try graph.addEdge(1, 3);
    try graph.addEdge(2, 4);

    var neighbors1 = graph.getNeighbors(1).?;
    try expectEqual(neighbors1.len, 2);
    try expect(try neighbors1.get(0) == 2);
    try expect(try neighbors1.get(1) == 3);

    var neighbors2 = graph.getNeighbors(2).?;
    try expectEqual(neighbors2.len, 1);
    try expect(try neighbors2.get(0) == 4);
}

test "containsNode" {
    const allocator = std.heap.page_allocator;
    var graph = AdjacencyList(u32, void).init(allocator);
    defer graph.deinit();

    try graph.addEdge(5, 6);
    try graph.addEdge(7, 8);

    try expect(graph.containsNode(5));
    try expect(graph.containsNode(7));
    try expect(!graph.containsNode(9));
}

test "getNeighbors returns null for missing node" {
    const allocator = std.heap.page_allocator;
    var graph = AdjacencyList(u32, void).init(allocator);
    defer graph.deinit();

    try expect(graph.getNeighbors(42) == null);
}

test "clear empties the graph" {
    const allocator = std.heap.page_allocator;
    var graph = AdjacencyList(u32, void).init(allocator);
    defer graph.deinit();

    try graph.addEdge(1, 2);
    try graph.addEdge(2, 3);
    try expectEqual(graph.size(), 2);

    graph.clear();
    try expectEqual(graph.size(), 0);
    try expect(graph.getNeighbors(1) == null);
    try expect(graph.getNeighbors(2) == null);
}
