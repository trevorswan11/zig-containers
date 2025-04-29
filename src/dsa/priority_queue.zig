const std = @import("std");
const array_list = @import("array.zig").Array;

/// Represents a heap, being a min-at-top by default
pub fn PriorityQueue(comptime T: type, comptime less: fn (a: T, b: T) bool, reverse: bool) type {
    return struct {
        const Self = @This();

        array: array_list(T),
        len: usize,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, inital_capacity: usize) !Self {
            const arr = try array_list(T).init(allocator, inital_capacity);
            return Self{
                .allocator = allocator,
                .array = arr,
                .len = arr.len,
            };
        }

        pub fn deinit(self: *Self) void {
            self.array.deinit();
        }

        fn siftUpMaxAtTop(self: *Self, i: usize) !void {
            const value: ?T = self.array.get(i);
            if (value) |to_sift| {
                var child = i;
                while (child > 0) {
                    const parent = (child - 1) / 2;
                    if (!less(self.array.get(parent), to_sift)) {
                        break;
                    }
                    self.array.set(child, self.array.get(parent));
                    child = parent;
                }
                self.array.set(child, to_sift);
            }
        }

        fn siftDownMaxAtTop(self: *Self, i: usize) !void {
            const value: ?T = self.array.get(i);
            if (value) |to_sift| {
                var parent: usize = i;
                var child: usize = 2 * parent + 1;
                while (child < self.len) {
                    if (child + 1 < self.len and less(self.array.get(child), self.array.get(child + 1))) {
                        child += 1;
                    }
                    if (!less(to_sift, self.array.get(child))) {
                        break;
                    }

                    self.array.set(parent, self.array.get(child));
                    self.array.set(child, to_sift);
                    parent = child;
                    child = 2 * parent + 1;
                }
                self.array.set(parent, to_sift);
            }
        }
    };
}