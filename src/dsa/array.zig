const std = @import("std");

const GROWTH_FACTOR: f32 = 1.5;

pub fn Array(comptime T: type) type {
    return struct {
        const Self = @This();

        arr: []T,
        len: usize,
        capacity: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, initial_capacity: usize) !Self {
            const arr = try allocator.alloc(T, initial_capacity);
            return Self{ .arr = arr, .len = 0, .capacity = if (initial_capacity > 0) initial_capacity else 1, .allocator = allocator };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.arr);
        }

        pub fn empty(self: *Self) bool {
            return self.len == 0;
        }

        pub fn push(self: *Self, value: T) !void {
            try self.grow();
            self.arr[self.len] = value;
            self.len += 1;
        }

        pub fn insert(self: *Self, index: usize, value: T) !void {
            if (index > self.len or index < 0) {
                return error.IndexOutOfBounds;
            }

            try self.grow();

            var i = self.len;
            while (i > index) : (i -= 1) {
                self.arr[i] = self.arr[i - 1];
            }

            self.arr[index] = value;
            self.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len <= 0) {
                self.len = 0;
                return null;
            }

            self.len -= 1;
            return self.arr[self.len];
        }

        pub fn get(self: *Self, index: usize) ?T {
            if (index >= self.len or index < 0) {
                return null;
            }
            return self.arr[index];
        }

        pub fn print(self: *Self) void {
            std.debug.print("[", .{});
            for (self.arr[0..self.len]) |value| {
                std.debug.print(" {} ", .{value});
            }
            std.debug.print("]", .{});
        }

        fn grow(self: *Self) !void {
            if (self.len >= self.capacity) {
                const new_capacity = calculateNewCapacity(self.capacity);
                const new_arr = try self.allocator.alloc(T, new_capacity);

                for (self.arr, 0..) |val, i| {
                    new_arr[i] = val;
                }
                self.allocator.free(self.arr);

                self.arr = new_arr;
                self.capacity = new_capacity;
            }
        }

        fn calculateNewCapacity(old_capacity: usize) usize {
            return @as(usize, @intFromFloat(@ceil(@as(f32, @floatFromInt(old_capacity)) * GROWTH_FACTOR)));
        }
    };
}

const testing = std.testing;
const expect = testing.expect;

test "array initialization" {
    const allocator = std.heap.page_allocator;
    var test_array = try Array(u32).init(allocator, 5);
    defer test_array.deinit();

    try expect(test_array.empty());
}

test "push" {
    const allocator = std.heap.page_allocator;
    var test_array = try Array(u32).init(allocator, 5);
    defer test_array.deinit();

    try test_array.push(2);
    try expect(test_array.get(0) == 2);

    for (3..10) |i| {
        try test_array.push(@intCast(i));
    }

    try expect(!test_array.empty());
}

test "insert" {
    const allocator = std.heap.page_allocator;
    var test_array = try Array(u32).init(allocator, 5);
    defer test_array.deinit();

    for (3..10) |i| {
        try test_array.push(@intCast(i));
    }

    try test_array.insert(0, 20);
    try test_array.insert(3, 10);

    try expect(test_array.get(0) == 20);
    try expect(test_array.get(3) == 10);

    try testing.expectError(error.IndexOutOfBounds, test_array.insert(200, 1));
}

test "pop" {
    const allocator = std.heap.page_allocator;
    var test_array = try Array(f32).init(allocator, 5);
    defer test_array.deinit();

    for (1..10) |i| {
        const to_put = 1.25 * @as(f32, @floatFromInt(i));
        try test_array.push(to_put);
        try expect(test_array.pop().? == to_put);
    }

    try expect(test_array.empty());
}

test "get" {
    const allocator = std.heap.page_allocator;
    var test_array = try Array(u32).init(allocator, 5);
    defer test_array.deinit();

    for (1..10) |i| {
        try test_array.push(@intCast(i));
    }

    for (0..9, 1..10) |idx, val| {
        try expect(test_array.get(idx) == @as(u32, @intCast(val)));
    }

    try expect(!test_array.empty());
}
