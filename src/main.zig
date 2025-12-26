const std = @import("std");

const rv32 = @import("isa/rv/rv.zig");

const elf32 = @import("elf.zig").Elf(u32);

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    var stdout_file = std.fs.File.stdout().writer(&.{});
    const stdout = &stdout_file.interface;

    var code_accum = std.Io.Writer.Allocating.init(allocator);
    defer code_accum.deinit();

    const writer = &code_accum.writer;

    const msg = "sesbian lex\n";

    try rv32.spec.addi.fun(writer, &.{
        .{ .register = .x0 },
        .{ .register = .x0 },
        .{ .immediate = 1 },
    });
    try rv32.spec.auipc.fun(writer, &.{
        .{ .register = .a1 },
        .{ .immediate = 0 },
    });
    try rv32.spec.addi.fun(writer, &.{
        .{ .register = .a1 },
        .{ .register = .a1 },
        .{ .immediate = 0 },
    });
    try rv32.spec.addi.fun(writer, &.{
        .{ .register = .a2 },
        .{ .register = .x0 },
        .{ .immediate = msg.len },
    });
    try rv32.spec.addi.fun(writer, &.{
        .{ .register = .a7 },
        .{ .register = .x0 },
        .{ .immediate = 64 },
    });
    try rv32.spec.ecall.fun(writer, &.{});

    try rv32.spec.addi.fun(writer, &.{
        .{ .register = .a0 },
        .{ .register = .x0 },
        .{ .immediate = 69 },
    });
    try rv32.spec.addi.fun(writer, &.{
        .{ .register = .a7 },
        .{ .register = .x0 },
        .{ .immediate = 93 },
    });
    try rv32.spec.ecall.fun(writer, &.{});

    const code = try code_accum.toOwnedSlice();
    defer allocator.free(code);

    try elf32.emit(allocator, stdout, .NONE, .RISCV, &.{
        elf32.Section.Abstract{
            .name = ".text",
            .data = code,
            .type = .PROGBITS,
            .flags = elf32.Section.Flag.ALLOC | elf32.Section.Flag.EXEC,
            .addralign = 0x4,
            .symbols = &.{
                elf32.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "_start",
                    .offset = 0,
                    .type = .FUNC,
                },
                elf32.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "pcrel_hi",
                    .offset = 4,
                    .type = .FUNC,
                },
            },
            .relocations = &.{
                elf32.Rela.Abstract{
                    .symbol = "msg",
                    .addend = 0,
                    .offset = 4,
                    .type = rv32.spec.auipc.relocation.pc_relative orelse unreachable,
                },
                elf32.Rela.Abstract{
                    .symbol = "pcrel_hi",
                    .addend = 0,
                    .offset = 8,
                    .type = rv32.spec.addi.relocation.pc_relative orelse unreachable,
                },
            },
            .rela_name = ".rela.text",
        },

        elf32.Section.Abstract{
            .name = ".data",
            .data = msg,
            .type = .PROGBITS,
            .flags = elf32.Section.Flag.ALLOC,
            .symbols = &.{
                elf32.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "msg",
                    .offset = 0,
                    .type = .OBJECT,
                },
            },
        },
    });
}
