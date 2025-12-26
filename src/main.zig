const std = @import("std");

const uwa = @import("uwa");

const riscv = uwa.arch.riscv.spec;
const elf = uwa.Elf32;

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

    try riscv.addi.fun(writer, &.{
        .{ .register = .x0 },
        .{ .register = .x0 },
        .{ .immediate = 1 },
    });
    try riscv.auipc.fun(writer, &.{
        .{ .register = .a1 },
        .{ .immediate = 0 },
    });
    try riscv.addi.fun(writer, &.{
        .{ .register = .a1 },
        .{ .register = .a1 },
        .{ .immediate = 0 },
    });
    try riscv.addi.fun(writer, &.{
        .{ .register = .a2 },
        .{ .register = .x0 },
        .{ .immediate = msg.len },
    });
    try riscv.addi.fun(writer, &.{
        .{ .register = .a7 },
        .{ .register = .x0 },
        .{ .immediate = 64 },
    });
    try riscv.ecall.fun(writer, &.{});

    try riscv.addi.fun(writer, &.{
        .{ .register = .a0 },
        .{ .register = .x0 },
        .{ .immediate = 69 },
    });
    try riscv.addi.fun(writer, &.{
        .{ .register = .a7 },
        .{ .register = .x0 },
        .{ .immediate = 93 },
    });
    try riscv.ecall.fun(writer, &.{});

    const code = try code_accum.toOwnedSlice();
    defer allocator.free(code);

    try elf.emit(allocator, stdout, .NONE, .RISCV, &.{
        elf.Section.Abstract{
            .name = ".text",
            .data = code,
            .type = .PROGBITS,
            .flags = elf.Section.Flag.ALLOC | elf.Section.Flag.EXEC,
            .addralign = 0x4,
            .symbols = &.{
                elf.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "_start",
                    .offset = 0,
                    .type = .FUNC,
                },
                elf.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "pcrel_hi",
                    .offset = 4,
                    .type = .FUNC,
                },
            },
            .relocations = &.{
                elf.Rela.Abstract{
                    .symbol = "msg",
                    .addend = 0,
                    .offset = 4,
                    .type = riscv.auipc.relocation.pc_relative orelse unreachable,
                },
                elf.Rela.Abstract{
                    .symbol = "pcrel_hi",
                    .addend = 0,
                    .offset = 8,
                    .type = riscv.addi.relocation.pc_relative orelse unreachable,
                },
            },
            .rela_name = ".rela.text",
        },

        elf.Section.Abstract{
            .name = ".data",
            .data = msg,
            .type = .PROGBITS,
            .flags = elf.Section.Flag.ALLOC,
            .symbols = &.{
                elf.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "msg",
                    .offset = 0,
                    .type = .OBJECT,
                },
            },
        },
    });
}
