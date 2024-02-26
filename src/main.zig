const std = @import("std");

const Evm = struct {
    stack: []u256,
    memory: []u8,
    code: []const u8,
    stack_pointer: usize,

    pub fn init(allocator: *std.mem.Allocator, code: []const u8, stack_size: usize) !Evm {
        var stack = try allocator.alloc(u256, stack_size);
        // Initialize stack values to zero
        for (stack) |*item| {
            item.* = 0;
        }
        return Evm{
            .stack = stack,
            .memory = try allocator.alloc(u8, 32 * 64), // Simplistic fixed-size memory
            .code = code,
            .stack_pointer = 0, // Initialize stack pointer
        };
    }

    pub fn push(self: *Evm, value: u256) !void {
        // Ensure we have space on the stack
        if (self.stack_pointer >= self.stack.len) return error.StackOverflow;

        // Push the value onto the stack
        self.stack[self.stack_pointer] = value;
        self.stack_pointer += 1; // Increment stack pointer
    }

    pub fn execute(self: *Evm) !void {
        var pc: usize = 0; // Program counter
        while (pc < self.code.len) {
            const opcode = self.code[pc];
            switch (opcode) {
                0x60 => { // PUSH1
                    pc += 1; // Move to the byte to push
                    const value = self.code[pc];
                    try self.push(value);
                    pc += 1; // Move to the next instruction
                },
                else => {
                    std.debug.print("Unknown opcode: {}\n", .{opcode});
                    return;
                },
            }
            std.debug.print("Executed instruction: {}\n", .{opcode});
            try self.print_state();
        }
    }

    pub fn print_state(self: *Evm) !void {
        std.debug.print("Stack pointer: {}\n", .{self.stack_pointer});
        std.debug.print("Memory : {X}\n", .{std.fmt.fmtSliceHexUpper(self.memory)});
        std.debug.print("Code: {any}\n", .{self.code});
        std.debug.print("Stack Pointer: {}\n", .{self.stack_pointer});
        for (self.stack) |*item| {
            std.debug.print("{d}\n", .{item.*});
        }
    }
};

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    // Example code to execute
    const code: []const u8 = &[_]u8{ 0x60, 0x10 }; // PUSH1 0x10 (for example)

    var evm = try Evm.init(&allocator, code, 32);
    try evm.execute();
}
