const std = @import("std");

const Register = @import("registers.zig").Register;

const RType = @import("types.zig").RType;
const IType = @import("types.zig").IType;
const SType = @import("types.zig").SType;
const BType = @import("types.zig").BType;
const UType = @import("types.zig").UType;
const JType = @import("types.zig").JType;

pub fn addi(writer: *std.Io.Writer, rd: Register, rs1: Register, imm: i12) !void {
    try writer.writeStruct(IType{
        .opcode = 0x13,
        .funct3 = 0x0,
        .rd = rd,
        .rs1 = rs1,
        .imm = @bitCast(imm),
    }, .little);
}

pub fn auipc(writer: *std.Io.Writer, rd: Register, imm: i20) !void {
    try writer.writeStruct(UType{
        .opcode = 0x17,
        .rd = rd,
        .imm = @bitCast(imm),
    }, .little);
}

pub fn ecall(writer: *std.Io.Writer) !void {
    try writer.writeStruct(IType{
        .opcode = 0x73,
        .funct3 = 0x0,
        .rd = .x0,
        .rs1 = .x0,
        .imm = 0x0,
    }, .little);
}
