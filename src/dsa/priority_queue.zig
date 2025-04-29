const std = @import("std");
const array_list = @import("array.zig").Array;

pub const PQType = enum {
    max_at_top, min_at_top
};

pub fn PriorityQueue(comptime T: type, comptime less: fn (a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        const Impl = union(enum) {
            max_at_top: MaxAtTopPQ(T, less),
            min_at_top: MinAtTopPQ(T, less),
        };
        
        impl: Impl,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, kind: PQType, initial_capacity: usize) !Self {
            return switch (kind) {
                .max_at_top => Self{
                    .impl = Impl{ .max_at_top = try MaxAtTopPQ(T, less).init(allocator, initial_capacity) },
                    .allocator = allocator,
                },
                .min_at_top => Self{
                    .impl = Impl{ .min_at_top = try MinAtTopPQ(T, less).init(allocator, initial_capacity) },
                    .allocator = allocator,
                },
            };
        }

        pub fn deinit(self: *Self) void {
            switch (self.impl) {
                .max_at_top => |*pq| pq.deinit(),
                .min_at_top => |*pq| pq.deinit(),
            }
        }

        pub fn size(self: *Self) usize {
            return switch (self.impl) {
                .max_at_top => |*pq| pq.array.len,
                .min_at_top => |*pq| pq.array.len,
            };
        }

        pub fn empty(self: *Self) bool {
            return switch (self.impl) {
                .max_at_top => |*pq| pq.array.len == 0,
                .min_at_top => |*pq| pq.array.len == 0,
            };
        }

        pub fn insert(self: *Self, value: T) !void {
            return switch (self.impl) {
                .max_at_top => |*pq| {
                    try pq.array.push(value);
                    try pq.siftUp(self.size() - 1);
                },
                .min_at_top => |*pq| {
                    try pq.array.push(value);
                    try pq.siftUp(self.size() - 1);
                },
            };
        }

        pub fn poll(self: *Self) !?T {
            if (self.empty()) {
                return null;
            }

            return switch (self.impl) {
                .max_at_top => |*pq| {
                    const to_remove = try pq.array.get(0);
                    const last_element = try pq.array.remove(self.size() - 1);
                    if (!self.empty()) {
                        try pq.array.set(0, last_element);
                        try pq.siftDown(0);
                    }
                    return to_remove;
                },
                .min_at_top => |*pq| {
                    const to_remove = try pq.array.get(0);
                    const last_element = try pq.array.remove(self.size() - 1);
                    if (!self.empty()) {
                        try pq.array.set(0, last_element);
                        try pq.siftDown(0);
                    }
                    return to_remove;
                },
            };
        }

        pub fn peek(self: *Self) !T {
            return try self.get(0);
        }

        pub fn get(self: *Self, i: usize) !T {
            return switch (self.impl) {
                .max_at_top => |*pq| try pq.array.get(i),
                .min_at_top => |*pq| try pq.array.get(i),
            };
        }

        pub fn heapify(self: *Self) !void {
            var position = (self.size() - 2) / 2;
            while (position >= 0) : (position -= 1) {
                switch (self.impl) {
                    .max_at_top => |*pq| pq.siftDown(position),
                    .min_at_top => |*pq| pq.siftDown(position),
                }
            }
        }

        pub fn print(self: *Self) void {
            switch (self.impl) {
                .max_at_top => |*pq| pq.array.print(),
                .min_at_top => |*pq| pq.array.print(),
            }
        }
    };
}

pub fn MaxAtTopPQ(comptime T: type, comptime less: fn (a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        array: array_list(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, inital_capacity: usize) !Self {
            const arr = try array_list(T).init(allocator, inital_capacity);
            return Self{
                .allocator = allocator,
                .array = arr,
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit();
        }

        fn siftUp(self: *Self, i_: usize) !void {
            var i = i_;
            while (i > 0) {
                const parent = (i - 1) / 2;
                if (!less(try self.array.get(parent), try self.array.get(i))) {
                    break;
                }
                try self.swap(i, parent);
                i = parent;
            }
        }

        fn siftDown(self: *Self, i_: usize) !void {
            var i = i_;
            while (true) {
                var largest = i;
                const left = 2 * i + 1;
                const right = 2 * i + 2;

                if (left < self.array.len and less(try self.array.get(largest), try self.array.get(left))) {
                    largest = left;
                }
                if (right < self.array.len and less(try self.array.get(largest), try self.array.get(right))) {
                    largest = right;
                }
                if (largest == i) {
                    break;
                }

                try self.swap(i, largest);
                i = largest;
            }
        }

        fn swap(self: *Self, i: usize, j: usize) !void {
            const temp = try self.array.get(i);
            try self.array.set(i, try self.array.get(j));
            try self.array.set(j, temp);
        }
    };
}

pub fn MinAtTopPQ(comptime T: type, comptime less: fn (a: T, b: T) bool) type {
    return struct {
        const Self = @This();

        array: array_list(T),
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, inital_capacity: usize) !Self {
            const arr = try array_list(T).init(allocator, inital_capacity);
            return Self{
                .allocator = allocator,
                .array = arr,
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit();
        }

        fn siftUp(self: *Self, i_: usize) !void {
            var i = i_;
            while (i > 0) {
                const parent = (i - 1) / 2;
                if (!less(try self.array.get(i), try self.array.get(parent))) {
                    break;
                }
                try self.swap(i, parent);
                i = parent;
            }
        }

        fn siftDown(self: *Self, i_: usize) !void {
            var i = i_;
            while (true) {
                var smallest = i;
                const left = 2 * i + 1;
                const right = 2 * i + 2;

                if (left < self.array.len and less(try self.array.get(left), try self.array.get(smallest))) {
                    smallest = left;
                }
                if (right < self.array.len and less(try self.array.get(right), try self.array.get(smallest))) {
                    smallest = right;
                }
                if (smallest == i) {
                    break;
                }

                try self.swap(i, smallest);
                i = smallest;
            }
        }

        fn swap(self: *Self, i: usize, j: usize) !void {
            const temp = try self.array.get(i);
            try self.array.set(i, try self.array.get(j));
            try self.array.set(j, temp);
        }
    };
}

const testing = std.testing;

fn lessThan(a: i32, b: i32) bool {
    return a < b;
}

test "PriorityQueue max_at_top basic insert and poll" {
    const allocator = std.heap.page_allocator;
    var pq = try PriorityQueue(i32, lessThan).init(allocator, PQType.max_at_top, 10);
    defer pq.deinit();

    try pq.insert(5);
    try pq.insert(10);
    try pq.insert(3);

    try testing.expectEqual(@as(usize, 3), pq.size());

    const first = try pq.poll();
    try testing.expectEqual(@as(i32, 10), first.?);

    const second = try pq.poll();
    try testing.expectEqual(@as(i32, 5), second.?);

    const third = try pq.poll();
    try testing.expectEqual(@as(i32, 3), third.?);

    try testing.expectEqual(true, pq.empty());
}

test "PriorityQueue min_at_top basic insert and poll" {
    const allocator = std.heap.page_allocator;
    var pq = try PriorityQueue(i32, lessThan).init(allocator, PQType.min_at_top, 10);
    defer pq.deinit();

    try pq.insert(5);
    try pq.insert(10);
    try pq.insert(3);

    try testing.expectEqual(@as(usize, 3), pq.size());

    const first = try pq.poll();
    try testing.expectEqual(@as(i32, 3), first.?);

    const second = try pq.poll();
    try testing.expectEqual(@as(i32, 5), second.?);

    const third = try pq.poll();
    try testing.expectEqual(@as(i32, 10), third.?);

    try testing.expectEqual(true, pq.empty());
}