const std = @import("std");

fn SpecMemory(comptime Register: type) type {
    return struct {
        base: ?Register,
        index: ?Register,
        scale: u8 = 1,
        disp: isize = 0,

        pub const Fn = *const fn (memory: SpecMemory(Register)) bool; // infinite compile time recursion jumpscare
    };
}

pub fn Spec(comptime Register: type, comptime memfn: ?SpecMemory(Register).Fn) type {
    return struct {
        pub const Relocation = struct {
            absolute: ?usize = null,
            pc_relative: ?usize = null,
        };

        pub const Memory = SpecMemory(Register);

        pub const Operand = union(Kind) {
            pub const Kind = enum { register, memory, immediate };

            register: Register,
            memory: Memory,
            immediate: isize,

            pub const Constraint = struct {
                register: type = Register,
                /// memory is null = instruction does not take memory
                memory: ?Memory.Fn = memfn,
                /// immediate is null = instruction does not take immediate
                immediate: ?struct {
                    bits: u8,
                    signed: bool,
                } = null,
            };
        };

        name: []const u8,
        operands: []const Operand.Kind,
        relocation: Relocation,
        constraint: Operand.Constraint,
        register: type = Register,
        fun: *const fn (*std.Io.Writer, []const Operand) callconv(.@"inline") anyerror!void, // inline because i intend to use wrapper functions to keep encoders reusable outside this project
    };
}
