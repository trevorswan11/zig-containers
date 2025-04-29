const std = @import("std");

pub fn HashSet(comptime K: type) type {
    const MapType = if (K == []const u8)
        std.StringHashMap(void)
    else
        std.AutoHashMap(K, void);

    return struct {
        const Self = @This();

        map: MapType,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) Self {
            return Self{
                .map = MapType.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn deinit(self: *Self) void {
            self.map.deinit();
        }

        pub fn insert(self: *Self, key: K) !void {
            try self.map.put(key, {});
        }

        pub fn remove(self: *Self, key: K) bool {
            return self.map.remove(key);
        }

        pub fn contains(self: *Self, key: K) bool {
            return self.map.contains(key);
        }

        pub fn clear(self: *Self) void {
            self.map.clearRetainingCapacity();
        }

        pub fn size(self: *Self) usize {
            return self.map.count();
        }

        pub fn empty(self: *Self) bool {
            return self.size() == 0;
        }
    };
}

const expect = std.testing.expect;

test "hash set with u32 keys" {
    var set = HashSet(u32).init(std.testing.allocator);
    defer set.deinit();

    try set.insert(42);
    try expect(set.contains(42));
    try expect(set.remove(42));
    try expect(!set.contains(42));
}

test "hash set with string keys" {
    var set = HashSet([]const u8).init(std.testing.allocator);
    defer set.deinit();

    try set.insert("hello");
    try expect(set.contains("hello"));
    try expect(set.remove("hello"));
    try expect(!set.contains("hello"));
}
