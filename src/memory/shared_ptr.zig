const std = @import("std");

pub fn SharedPtr(comptime T: type) type {
    return struct {
        const Self = @This();

        ref_count: *usize,
        ptr: *T,

        pub fn init(value: T) !Self {
            const allocator = std.heap.page_allocator;
            const rc = try allocator.create(usize);
            rc.* = 1;

            const p = try allocator.create(T);
            p.* = value;

            return Self{
                .ref_count = rc,
                .ptr = p,
            };
        }

        pub fn clone(self: *Self) Self {
            self.ref_count.* += 1;
            return Self{
                .ref_count = self.ref_count,
                .ptr = self.ptr,
            };
        }

        pub fn release(self: *Self) void {
            const allocator = std.heap.page_allocator;
            self.ref_count.* -= 1;
            if (self.ref_count.* == 0) {
                allocator.destroy(self.ptr);
                allocator.destroy(self.ref_count);
            }
        }

        pub fn get(self: Self) *T {
            return self.ptr;
        }

        pub fn strongCount(self: Self) usize {
            return self.ref_count.*;
        }
    };
}

test "Ref basic usage" {
    var r = try SharedPtr(i32).init(100);
    defer r.release();

    try std.testing.expectEqual(@as(i32, 100), r.get().*);
}

test "Ref cloning increases count" {
    var r1 = try SharedPtr(i32).init(200);
    var r2 = r1.clone();

    try std.testing.expectEqual(@as(usize, 2), r1.strongCount());
    try std.testing.expectEqual(@as(usize, 2), r2.strongCount());

    defer r1.release();
    defer r2.release();
}

test "Ref multiple clones and releases" {
    var r1 = try SharedPtr(i32).init(300);
    var r2 = r1.clone();
    var r3 = r2.clone();

    try std.testing.expectEqual(@as(usize, 3), r1.strongCount());

    r1.release();
    try std.testing.expectEqual(@as(usize, 2), r2.strongCount());

    r2.release();
    try std.testing.expectEqual(@as(usize, 1), r3.strongCount());

    r3.release();
    // Memory is freed after this, zig should not be upset!
}

test "Ref stress test with many clones" {
    var r = try SharedPtr(i32).init(999);
    var clones: [1000]SharedPtr(i32) = undefined;

    // Clone it 1000 times
    var i: usize = 0;
    while (i < clones.len) : (i += 1) {
        clones[i] = r.clone();
    }

    // Now randomly release them
    i = 0;
    while (i < clones.len) : (i += 1) {
        clones[i].release();
    }

    // Original still alive
    try std.testing.expectEqual(@as(i32, 999), r.get().*);
    try std.testing.expectEqual(@as(usize, 1), r.strongCount());

    r.release(); // Now memory is freed
}
