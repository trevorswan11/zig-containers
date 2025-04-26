const std = @import("std");
const lib = @import("zig_containers_lib");

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    var woah = try lib.Array(u32).init(allocator, 4);
    defer woah.deinit();

    try woah.push(1);
    try woah.push(2);
    try woah.push(3);
    try woah.push(4);
    try woah.push(5);
    try woah.insert(1, 7);

    woah.print();
}
