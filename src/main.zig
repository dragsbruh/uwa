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

    var code_accum = std.Io.Writer.Allocating.init(allocator);
    defer code_accum.deinit();

    const writer = &code_accum.writer;

    const msg = "sesbian lex\n";

    try rv32.encoder.addi(writer, .a0, .x0, 1);
    try rv32.encoder.auipc(writer, .a1, 0);
    try rv32.encoder.addi(writer, .a1, .a1, 0);
    try rv32.encoder.addi(writer, .a2, .x0, msg.len);
    try rv32.encoder.addi(writer, .a7, .x0, 64);
    try rv32.encoder.ecall(writer);

    try rv32.encoder.addi(writer, .a0, .x0, 69);
    try rv32.encoder.addi(writer, .a7, .x0, 93);
    try rv32.encoder.ecall(writer);

    const code = try code_accum.toOwnedSlice();
    defer allocator.free(code);

    const choice = elf32;

    try choice.emit(allocator, stdout, .NONE, .RISCV, &.{
        choice.Section.Abstract{
            .name = ".text",
            .data = code,
            .type = .PROGBITS,
            .flags = choice.Section.Flag.ALLOC | choice.Section.Flag.EXEC,
            .addralign = 0x4,
            .symbols = &.{
                choice.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "_start",
                    .offset = 0,
                    .type = .FUNC,
                },
                choice.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "pcrel_hi",
                    .offset = 4,
                    .type = .FUNC,
                },
            },
            .relocations = &.{
                choice.Rela.Abstract{
                    .symbol = "msg",
                    .addend = 0,
                    .offset = 4,
                    .type = 23,
                },
                choice.Rela.Abstract{
                    .symbol = "pcrel_hi",
                    .addend = 0,
                    .offset = 8,
                    .type = 24,
                },
            },
            .rela_name = ".rela.text",
        },

        choice.Section.Abstract{
            .name = ".data",
            .data = msg,
            .type = .PROGBITS,
            .flags = choice.Section.Flag.ALLOC,
            .symbols = &.{
                choice.Symbol.Abstract{
                    .binding = .GLOBAL,
                    .name = "msg",
                    .offset = 0,
                    .type = .OBJECT,
                },
            },
        },
    });
}
