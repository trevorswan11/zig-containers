const std = @import("std");
const array = @import("array.zig").Array;
const queue = @import("Queue.zig").Queue;
const hash_set = @import("hash_set.zig").HashSet;
const adjacency_list = @import("adjacency_list.zig").AdjacencyList;

/// T must be hashable
pub fn Graph(comptime T: type) type {
    return struct {
        const Self = @This();

        adj_list: adjacency_list(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .allocator = allocator,
                .adj_list = adjacency_list(T).init(allocator),
            };
        }

        pub fn deinit(self: *Self) void {
            var it = self.adj_list.map.map.iterator();
            while (it.next()) |entry| {
                entry.value_ptr.*.deinit();
            }
            self.adj_list.deinit();
        }

        pub fn addEdge(self: *Self, from: T, to: T) !void {
            try self.ensureNode(from);
            try self.ensureNode(to);
            try self.adj_list.addEdge(from, to);
        }

        pub fn hasEdge(self: *Self, from: T, to: T) bool {
            if (self.adj_list.getNeighbors(from)) |list| {
                for (list.arr) |neighbor| {
                    if (neighbor == to) {
                        return true;
                    }
                }
            }
            return false;
        }

        fn ensureNode(self: *Self, id: T) !void {
            try self.adj_list.put(id);
        }

        pub fn hasNode(self: *Self, id: T) bool {
            return self.adj_list.containsNode(id);
        }

        pub fn getNeighbors(self: *Self, id: T) ?array(T) {
            return self.adj_list.getNeighbors(id);
        }

        pub fn print(self: *Self) void {
            var it = self.adj_list.map.map.iterator();
            while (it.next()) |entry| {
                std.debug.print("Node {}: ", .{entry.key_ptr.*});
                entry.value_ptr.*.print();
                std.debug.print("\n", .{});
            }
        }

        pub fn clear(self: *Self) void {
            self.adj_list.clear();
        }

        pub fn bfs(self: *Self, start: T, ctx: anytype, visitor: fn (@TypeOf(ctx), T) void) void {
            if (!self.hasNode(start)) {
                return;
            }

            var visited = hash_set(T).init(self.allocator);
            defer visited.deinit();

            var q = queue(T).init(self.allocator) catch return;
            defer q.deinit();

            visited.insert(start) catch return;
            q.push(start) catch return;

            while (q.list.len > 0) {
                var current: T = undefined;
                if (q.poll()) |val| {
                    current = val;
                } else unreachable;

                visitor(ctx, current);

                if (self.getNeighbors(current)) |neighbors| {
                    for (0..neighbors.len) |i| {
                        if (!visited.contains(neighbors.arr[i])) {
                            visited.insert(neighbors.arr[i]) catch return;
                            q.push(neighbors.arr[i]) catch return;
                        }
                    }
                }
            }
        }

        pub fn dfs(self: *Self, start: T, ctx: anytype, visitor: fn (@TypeOf(ctx), T) void) void {
            if (!self.hasNode(start)) {
                return;
            }

            var visited = hash_set(T).init(self.allocator);
            defer visited.deinit();

            self.dfsHelper(start, ctx, visitor, &visited);
        }

        fn dfsHelper(
            self: *Self,
            current: T,
            ctx: anytype,
            visitor: fn (@TypeOf(ctx), T) void,
            visited: *hash_set(T),
        ) void {
            if (visited.contains(current)) {
                return;
            }

            visited.insert(current) catch return;
            visitor(ctx, current);

            if (self.getNeighbors(current)) |neighbors| {
                for (0..neighbors.len) |i| {
                    self.dfsHelper(neighbors.arr[i], ctx, visitor, visited);
                }
            }
        }
    };
}

const testing = std.testing;

test "basic graph operations" {
    const allocator = std.testing.allocator;
    var graph = Graph(u32).init(allocator);
    defer graph.deinit();

    try graph.addEdge(1, 2);
    try graph.addEdge(1, 3);
    try graph.addEdge(2, 4);
    try graph.addEdge(3, 4);

    try testing.expect(graph.hasNode(1));
    try testing.expect(graph.hasNode(4));
    try testing.expect(!graph.hasNode(99));

    try testing.expect(graph.hasEdge(1, 2));
    try testing.expect(!graph.hasEdge(2, 1));

    if (graph.getNeighbors(1)) |neighbors| {
        try testing.expectEqual(@as(usize, 2), neighbors.len);
    } else {
        return error.UnexpectedNull;
    }

    var bfs_result = try array(u32).init(allocator, 7);
    defer bfs_result.deinit();

    const BfsCtx = struct {
        result: *array(u32),
        fn visit(ctx: *@This(), n: u32) void {
            ctx.result.push(n) catch unreachable;
        }
    };

    var bfs_ctx = BfsCtx{ .result = &bfs_result };
    graph.bfs(1, &bfs_ctx, BfsCtx.visit);
    try testing.expectEqualSlices(u32, &[_]u32{ 1, 2, 3, 4 }, bfs_result.arr[0..4]);

    var dfs_result = try array(u32).init(allocator, 7);
    defer dfs_result.deinit();

    const DfsCtx = struct {
        result: *array(u32),
        fn visit(ctx: *@This(), n: u32) void {
            ctx.result.push(n) catch unreachable;
        }
    };

    var dfs_ctx = DfsCtx{ .result = &dfs_result };
    graph.dfs(1, &dfs_ctx, DfsCtx.visit);
    try testing.expect(dfs_result.len >= 4);
}

test "put then addEdge maintains consistency" {
    const allocator = std.heap.page_allocator;
    var graph = adjacency_list(u32).init(allocator);
    defer graph.deinit();

    try graph.put(100);
    try graph.put(200);
    try graph.addEdge(100, 200);

    var neighbors = graph.getNeighbors(100).?;
    try testing.expectEqual(neighbors.len, 1);
    try testing.expect(try neighbors.get(0) == 200);
}

test "self-loop edge is allowed" {
    const allocator = std.heap.page_allocator;
    var graph = adjacency_list(u32).init(allocator);
    defer graph.deinit();

    try graph.addEdge(9, 9);
    var neighbors = graph.getNeighbors(9).?;
    try testing.expectEqual(neighbors.len, 1);
    try testing.expect(try neighbors.get(0) == 9);
}

test "graph supports many nodes and edges" {
    const allocator = std.heap.page_allocator;
    var graph = adjacency_list(usize).init(allocator);
    defer graph.deinit();

    for (0..100) |i| {
        try graph.put(i);
    }

    for (0..100) |i| {
        try graph.addEdge(i, (i + 1) % 100);
    }

    for (0..100) |i| {
        var neighbors = graph.getNeighbors(i).?;
        try testing.expectEqual(neighbors.len, 1);
        try testing.expect(try neighbors.get(0) == ((i + 1) % 100));
    }
}

test "clear then reuse graph" {
    const allocator = std.heap.page_allocator;
    var graph = adjacency_list(u32).init(allocator);
    defer graph.deinit();

    try graph.addEdge(1, 2);
    try graph.addEdge(2, 3);
    graph.clear();

    try testing.expect(graph.getNeighbors(1) == null);
    try testing.expect(graph.getNeighbors(2) == null);

    try graph.addEdge(4, 5);
    var neighbors = graph.getNeighbors(4).?;
    try testing.expectEqual(neighbors.len, 1);
    try testing.expect(try neighbors.get(0) == 5);
}

test "addEdge implicitly adds node" {
    const allocator = std.heap.page_allocator;
    var graph = adjacency_list(u32).init(allocator);
    defer graph.deinit();

    try graph.addEdge(77, 88); // 77 not explicitly put before
    try testing.expect(graph.containsNode(77));
    try testing.expect(graph.containsNode(88) == false);

    var neighbors = graph.getNeighbors(77).?;
    try testing.expectEqual(neighbors.len, 1);
    try testing.expect(try neighbors.get(0) == 88);
}
