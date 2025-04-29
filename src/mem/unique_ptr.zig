const std = @import("std");

pub fn UniquePtr(comptime T: type) type {
    return struct {
        ptr: ?*T,

        pub fn init(value: T) !UniquePtr(T) {
            const allocator = std.heap.page_allocator;
            const p = try allocator.create(T);
            p.* = value;
            return UniquePtr(T){ .ptr = p };
        }

        pub fn deinit(self: *UniquePtr(T)) void {
            if (self.ptr) |p| {
                const allocator = std.heap.page_allocator;
                allocator.destroy(p);
                self.ptr = null;
            }
        }

        pub fn get(self: UniquePtr(T)) ?*T {
            return self.ptr;
        }

        pub fn move(self: *UniquePtr(T)) !?*T {
            const p = self.ptr orelse @panic("Scope was moved already!");
            self.ptr = null;
            return p;
        }
    };
}

test "Scope basic usage" {
    var s = try UniquePtr(i32).init(10);
    defer s.deinit();

    try std.testing.expectEqual(@as(i32, 10), s.get().?.*);
}

test "Scope move semantics" {
    var s = try UniquePtr(i32).init(20);
    defer s.deinit();

    const raw = try s.move();
    try std.testing.expectEqual(@as(i32, 20), raw.?.*);
}
