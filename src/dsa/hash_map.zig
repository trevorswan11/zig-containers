const std = @import("std");

pub fn HashMap(comptime K: type, comptime V: type) type {
    const MapType = if (K == []const u8)
        std.StringHashMap(V)
    else
        std.AutoHashMap(K, V);

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

        pub fn size(self: *Self) usize {
            return @as(usize, self.map.count());
        }

        pub fn put(self: *Self, key: K, value: V) !void {
            try self.map.put(key, value);
        }

        pub fn find(self: *Self, key: K) ?V {
            return self.map.get(key);
        }

        pub fn remove(self: *Self, key: K) ?V {
            const pair = self.map.fetchRemove(key);
            if (pair) |kv| {
                return kv.value;
            } else {
                return null;
            }
        }

        pub fn containsKey(self: *Self, key: K) bool {
            return self.map.contains(key);
        }

        pub fn clear(self: *Self) void {
            self.map.clearRetainingCapacity();
        }
    };
}

const testing = std.testing;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

test "hash map initialization" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try expect(map.size() == 0);
}

test "put and find" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try map.put(1, 100);
    try map.put(2, 200);
    try expect(map.size() == 2);

    try expect(map.find(1).? == 100);
    try expect(map.find(2).? == 200);
}

test "overwrite existing key" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try map.put(42, 500);
    try map.put(42, 999);

    try expect(map.size() == 1);
    try expect(map.find(42).? == 999);
}

test "remove key" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try map.put(77, 1234);
    const removed = map.remove(77);
    try expect(removed.? == 1234);
    try expect(map.size() == 0);
    try expect(map.find(77) == null);
}

test "containsKey" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try map.put(8, 800);
    try map.put(9, 900);

    try expect(map.containsKey(8));
    try expect(map.containsKey(9));
    try expect(!map.containsKey(10));
}

test "remove non-existent key returns null" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try expect(map.remove(404) == null);
}

test "clear empties the map" {
    const allocator = std.heap.page_allocator;
    var map = HashMap(u32, u32).init(allocator);
    defer map.map.deinit();

    try map.put(1, 11);
    try map.put(2, 22);
    try map.put(3, 33);

    try expect(map.size() == 3);
    map.clear();
    try expect(map.size() == 0);
    try expect(!map.containsKey(1));
    try expect(!map.containsKey(2));
    try expect(!map.containsKey(3));
}

test "hash map with string key" {
    var map = HashMap([]const u8, u32).init(std.testing.allocator);
    defer map.deinit();

    try map.put("key", 99);
    try expect(map.containsKey("key"));
    try expect(map.find("key").? == 99);
    try expect(map.remove("key").? == 99);
    try expect(!map.containsKey("key"));
}
