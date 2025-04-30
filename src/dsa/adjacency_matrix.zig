const std = @import("std");

pub fn AdjacencyMatrix(comptime T: type) type {
    return struct {
        const Self = @This();

        matrix: [][]Node,
        size: usize,
        edge_count: usize = 0,
        allocator: std.mem.Allocator,

        pub const Node = struct {
            data: T,
            flag: bool,
        };

        pub fn init(allocator: std.mem.Allocator, size: usize) !Self {
            const matrix = try allocator.alloc([]Node, size);
            for (matrix) |*row| {
                row.* = try allocator.alloc(Node, size);
                for (0..row.len) |i| {
                    row.*[i] = Node{
                        .data = undefined,
                        .flag = false,
                    };
                }
            }

            return Self{
                .matrix = matrix,
                .size = size,
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            for (self.matrix) |row| {
                self.allocator.free(row);
            }
            self.allocator.free(self.matrix);
        }

        pub fn addEdge(self: *Self, from: usize, to: usize) !void {
            if (from >= self.size or to >= self.size) {
                return error.IndexOutOfBounds;
            }
            self.matrix[from][to].flag = true;
            self.matrix[to][from].flag = true;
            self.edge_count += 1;
        }

        pub fn removeEdge(self: *Self, from: usize, to: usize) !void {
            if (from >= self.size or to >= self.size) {
                return error.IndexOutOfBounds;
            }
            self.matrix[from][to].flag = false;
            self.matrix[to][from].flag = false;
            self.edge_count -= 1;
        }

        pub fn getNeighbors(self: *Self, node: usize) ?[]Node {
            if (node >= self.size) {
                return null;
            }
            return self.matrix[node];
        }

        pub fn containsEdge(self: *Self, from: usize, to: usize) ?Node {
            if (from >= self.size or to >= self.size) {
                return null;
            }
            return self.matrix[from][to];
        }
    };
}

const testing = std.testing;
const expect = testing.expect;
const expectEqual = testing.expectEqual;

test "initialize adjacency matrix" {
    const allocator = std.testing.allocator;
    var matrix = try AdjacencyMatrix(u32).init(allocator, 3);
    defer matrix.deinit();

    try expectEqual(matrix.size, 3);
    try expectEqual(matrix.edge_count, 0);
}

test "add and check edge" {
    const allocator = std.testing.allocator;
    var matrix = try AdjacencyMatrix(u8).init(allocator, 4);
    defer matrix.deinit();

    try matrix.addEdge(0, 1);
    try matrix.addEdge(1, 2);

    try expect(matrix.containsEdge(0, 1).?.flag);
    try expect(matrix.containsEdge(1, 0).?.flag); // undirected
    try expect(matrix.containsEdge(1, 2).?.flag);
    try expect(!matrix.containsEdge(0, 2).?.flag);

    try expectEqual(matrix.edge_count, 2);
}

test "remove edge" {
    const allocator = std.testing.allocator;
    var matrix = try AdjacencyMatrix(void).init(allocator, 3);
    defer matrix.deinit();

    try matrix.addEdge(0, 1);
    try expect(matrix.containsEdge(1, 0).?.flag);
    try expectEqual(matrix.edge_count, 1);

    try matrix.removeEdge(0, 1);
    try expect(!matrix.containsEdge(0, 1).?.flag);
    try expectEqual(matrix.edge_count, 0);
}

test "get neighbors" {
    const allocator = std.testing.allocator;
    var matrix = try AdjacencyMatrix(u32).init(allocator, 3);
    defer matrix.deinit();

    try matrix.addEdge(0, 1);
    try matrix.addEdge(0, 2);

    const neighbors = matrix.getNeighbors(0).?;
    try expect(neighbors[1].flag);
    try expect(neighbors[2].flag);
    try expect(!neighbors[0].flag);
}

test "out-of-bounds edge operations return error/null" {
    const allocator = std.testing.allocator;
    var matrix = try AdjacencyMatrix(u32).init(allocator, 2);
    defer matrix.deinit();

    try std.testing.expectError(error.IndexOutOfBounds, matrix.addEdge(0, 2));
    try std.testing.expectError(error.IndexOutOfBounds, matrix.removeEdge(2, 1));

    try expect(matrix.getNeighbors(5) == null);
    try expect(matrix.containsEdge(5, 1) == null);
}
