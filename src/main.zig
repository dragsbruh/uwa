const std = @import("std");

const rv32 = @import("isa/rv32i.zig");

const elf32 = @import("elf.zig").Elf(u32);
const elf64 = @import("elf.zig").Elf(u64);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var stdout_file = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_file.interface;

    var code_writer = std.Io.Writer.Allocating.init(allocator);
    defer code_writer.deinit();

    try (rv32.Instruction{ .addi = .{ rv32.Register.Alias.a0.resolve(), rv32.Register.x0, 69 } }).native().write(&code_writer.writer);
    try (rv32.Instruction{ .addi = .{ rv32.Register.Alias.a7.resolve(), rv32.Register.x0, 93 } }).native().write(&code_writer.writer); // sys_exit
    try (rv32.Instruction{ .ecall = {} }).native().write(&code_writer.writer);

    const code = try code_writer.toOwnedSlice();
    defer allocator.free(code);

    const choice = elf32;

    try choice.emit(allocator, stdout, .NONE, .RISCV, &.{
        choice.Section.Abstract{
            .name = ".text",
            .data = code,
            .type = .PROGBITS,
            .flags = choice.Section.Flag.ALLOC | choice.Section.Flag.EXEC,
            .addralign = 0x4,
            .symbols = &.{choice.Symbol.Abstract{
                .binding = .GLOBAL,
                .name = "_start",
                .offset = 0,
                .type = .FUNC,
            }},
        },
    });
}
