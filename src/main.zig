const std = @import("std");
const lib = @import("zig_containers_lib");

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // Array
    var array = try lib.Array(i32).init(allocator, 10);
    defer array.deinit();
    try array.push(5);
    std.debug.print("Array[0] = {}\n", .{try array.get(0)});
    std.debug.print("Array str = {s}\n", .{try array.toString()});

    // List
    var list = try lib.List(i32).init(allocator);
    defer list.deinit();
    try list.append(10);
    std.debug.print("List head = {}\n", .{list.head.?.value});
    std.debug.print("List = {s}\n", .{try list.toString()});

    // Queue
    var queue = try lib.Queue(i32).init(allocator);
    defer queue.deinit();
    try queue.push(20);
    const dequeued = queue.poll();
    std.debug.print("Queue dequeued = {any}\n", .{dequeued});
    std.debug.print("Queue = {s}\n", .{try queue.toString()});

    // Stack
    var stack = try lib.Stack(i32).init(allocator);
    defer stack.deinit();
    try stack.push(30);
    const popped = stack.pop();
    std.debug.print("Stack popped = {any}\n", .{popped});
    std.debug.print("Stack = {s}\n", .{try stack.toString()});

    // Deque
    var deque = try lib.Deque(i32).init(allocator);
    defer deque.deinit();
    try deque.pushHead(40);
    try deque.pushTail(50);
    const front = deque.popHead();
    const back = deque.popTail();
    std.debug.print("Deque front = {any}, back = {any}\n", .{ front, back });
    std.debug.print("Deque = {s}\n", .{try deque.toString()});

    // PriorityQueue
    var pq = try lib.PriorityQueue(i32, lessThanInt).init(allocator, .min_at_top, @as(usize, 4));
    defer pq.deinit();
    try pq.insert(100);
    try pq.insert(50);
    std.debug.print("PriorityQueue min = {}\n", .{try pq.peek()});
    std.debug.print("PriorityQueue = {s}\n", .{try pq.toString()});

    // HashMap
    var map = try lib.HashMap([]const u8, i32, void).init(allocator);
    defer map.deinit();
    try map.put("a", 123);
    if (map.find("a")) |val| {
        std.debug.print("HashMap[\"a\"] = {}\n", .{val});
    }
    std.debug.print("HashMap = {s}\n", .{try map.toString()});

    // HashSet
    var set = try lib.HashSet([]const u8, void).init(allocator);
    defer set.deinit();
    try set.insert("zig");
    std.debug.print("HashSet contains 'zig' = {}\n", .{set.contains("zig")});
    std.debug.print("HashSet = {s}\n", .{try set.toString()});
}

fn lessThanInt(a: i32, b: i32) bool {
    return a < b;
}

fn eqlInt(a: i32, b: i32) bool {
    return a == b;
}
