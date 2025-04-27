// Data structures
pub const Array = @import("linear/array.zig").Array;
pub const List = @import("linear/list.zig").List;

// Memory
pub const Ref = @import("memory/shared_ptr.zig").SharedPtr;
pub const Scope = @import("memory/unique_ptr.zig").UniquePtr;