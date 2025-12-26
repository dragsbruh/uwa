const std = @import("std");

const encoder = @import("instructions.zig");

const Register = @import("registers.zig").Register;
const Spec = @import("../spec.zig").Spec(Register, null);

pub inline fn addi(writer: *std.Io.Writer, operands: []const Spec.Operand) !void {
    return encoder.addi(writer, operands[0].register, operands[1].register, @intCast(operands[2].immediate));
}

pub inline fn auipc(writer: *std.Io.Writer, operands: []const Spec.Operand) !void {
    return encoder.auipc(writer, operands[0].register, @intCast(operands[1].immediate));
}

pub inline fn ecall(writer: *std.Io.Writer, _: []const Spec.Operand) !void {
    return encoder.ecall(writer);
}
