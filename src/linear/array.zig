const std = @import("std");

const GROWTH_FACTOR: f32 = 2.0;

pub fn array(comptime T: type) type {
    return struct {
        const Self = @This();
        arr: []T,
        len: usize,
        capacity: usize,

        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator, initial_capacity: usize) !Self {
            const arr = try allocator.alloc(T, initial_capacity);
            return Self{
                .arr = arr,
                .len = 0,
                .capacity = initial_capacity,
                .allocator = allocator
            };
        }

        pub fn deinit(self: *Self) void {
            self.allocator.free(self.arr);
        }

        pub fn push(self: *Self, value: T) !void {
            if (self.len >= self.capacity) {
                const new_capacity = calculate_new_capacity(self.capacity);
                const new_arr = try self.allocator.alloc(T, new_capacity);

                for (self.arr, 0..) |val, i| {
                    new_arr[i] = val;
                }
                self.allocator.free(self.arr);

                self.arr = new_arr;
                self.capacity = new_capacity;
            }

            self.arr[self.len] = value;
            self.len += 1;
        }

        pub fn pop(self: *Self) ?T {
            if (self.len <= 0) {
                return null;
            }
            
            self.len -= 1;
            return self.arr[self.len];
        }

        fn calculate_new_capacity(old_capacity: usize) usize {
            return @as(usize, @intFromFloat(@floor(@as(f32, @floatFromInt(old_capacity)) * GROWTH_FACTOR)));
        }

        pub fn get(self: *Self, index: usize) ?T {
            if (index >= self.len or index < 0) {
                return null;
            }
            return self.arr[index];
        }

        pub fn print(self: *Self) void {
            for (self.arr[0..self.len], 0..) |value, idx| {
                std.debug.print("arr[{}] = {}\n", .{idx, value});
            }
        }
    };
}

const testing = std.testing;

test "array initialization" {
    const allocator = std.heap.page_allocator;
    var test_array = try array(u32).init(allocator, 5);
    defer test_array.deinit();
}

test "push operations" {
    const allocator = std.heap.page_allocator;
    var test_array = try array(u32).init(allocator, 5);
    defer test_array.deinit();

    try test_array.push(2);
    try testing.expect(test_array.get(0) == 3);
}