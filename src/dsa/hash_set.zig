const std = @import("std");

pub fn HashSet(comptime K: type, comptime Ctx: type) type {
    const MapType = if (K == []const u8)
        std.StringHashMap(void)
    else if (Ctx == void)
        std.AutoHashMap(K, void)
    else
        std.HashMap(K, void, Ctx, 80);

    return struct {
        const Self = @This();

        map: MapType,
        allocator: std.mem.Allocator,

        pub fn init(allocator: std.mem.Allocator) !Self {
            if (Ctx != void) {
                if (!@hasDecl(Ctx, "eql") or !@hasDecl(Ctx, "hash")) {
                    return error.MalformedHashContext;
                }
                const default_ctx = Ctx{};
                return Self{
                    .map = MapType.initContext(allocator, default_ctx),
                    .allocator = allocator,
                };
            }
            return Self{
                .map = MapType.init(allocator),
                .allocator = allocator,
            };
        }

        pub fn initContext(allocator: std.mem.Allocator, context: Ctx) !Self {
            if (!@hasDecl(Ctx, "eql") or !@hasDecl(Ctx, "hash")) {
                return error.MalformedHashContext;
            }

            return Self{
                .map = MapType.initContext(allocator, context),
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
    var set = try HashSet(u32, void).init(std.testing.allocator);
    defer set.deinit();

    try set.insert(42);
    try expect(set.contains(42));
    try expect(set.remove(42));
    try expect(!set.contains(42));
}

test "hash set with string keys" {
    var set = try HashSet([]const u8, void).init(std.testing.allocator);
    defer set.deinit();

    try set.insert("hello");
    try expect(set.contains("hello"));
    try expect(set.remove("hello"));
    try expect(!set.contains("hello"));
}

const MyCtx = struct {
    pub fn hash(_: @This(), key: u32) u64 {
        return key * 31;
    }

    pub fn eql(_: @This(), a: u32, b: u32) bool {
        return a == b;
    }
};

test "hash set with u32 keys using custom context" {
    var set = try HashSet(u32, MyCtx).init(std.testing.allocator);
    defer set.deinit();

    try set.insert(42);
    try std.testing.expect(set.contains(42));
    try std.testing.expect(set.remove(42));
    try std.testing.expect(!set.contains(42));
}

const BadCtx = struct {
    // Missing `eql`
    pub fn hash(_: @This(), key: u32) u64 {
        return key;
    }
};

test "hash set with bad context fails" {
    const result = HashSet(u32, BadCtx).init(std.testing.allocator);
    try std.testing.expectError(error.MalformedHashContext, result);
}
