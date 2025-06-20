// Data structures and Algorithms
pub const Array = @import("dsa/array.zig").Array;
pub const List = @import("dsa/list.zig").List;
pub const Queue = @import("dsa/queue.zig").Queue;
pub const Stack = @import("dsa/stack.zig").Stack;
pub const Deque = @import("dsa/deque.zig").Deque;
pub const Treap = @import("dsa/treap.zig").Treap;
pub const PriorityQueue = @import("dsa/priority_queue.zig").PriorityQueue;
pub const PQType = @import("dsa/priority_queue.zig").PQType;
pub const HashMap = @import("dsa/hash_map.zig").HashMap;
pub const HashSet = @import("dsa/hash_set.zig").HashSet;
pub const Graph = @import("dsa/graph.zig").Graph;
pub const AdjacencyList = @import("dsa/adjacency_list.zig").AdjacencyList;
pub const AdjacencyMatrix = @import("dsa/adjacency_matrix.zig").AdjacencyMatrix;

// Memory
pub const Ref = @import("mem/shared_ptr.zig").SharedPtr;
pub const Scope = @import("mem/unique_ptr.zig").UniquePtr;

test {
    _ = @import("dsa/array.zig");
    _ = @import("dsa/list.zig");
    _ = @import("dsa/queue.zig");
    _ = @import("dsa/stack.zig");
    _ = @import("dsa/deque.zig");
    _ = @import("dsa/treap.zig");
    _ = @import("dsa/priority_queue.zig");
    _ = @import("dsa/hash_map.zig");
    _ = @import("dsa/hash_set.zig");
    _ = @import("dsa/graph.zig");
    _ = @import("dsa/adjacency_list.zig");
    _ = @import("dsa/adjacency_matrix.zig");

    _ = @import("mem/shared_ptr.zig");
    _ = @import("mem/unique_ptr.zig");
}
