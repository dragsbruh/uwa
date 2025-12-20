const std = @import("std");

pub const Register = enum(u5) {
    pub const Alias = enum(u5) {
        zero = 0,
        ra = 1,
        sp = 2,
        gp = 3,
        tp = 4,

        t0 = 5,
        t1 = 6,
        t2 = 7,

        s0 = 8,
        s1 = 9,

        a0 = 10,
        a1 = 11,
        a2 = 12,
        a3 = 13,
        a4 = 14,
        a5 = 15,
        a6 = 16,
        a7 = 17,

        s2 = 18,
        s3 = 19,
        s4 = 20,
        s5 = 21,
        s6 = 22,
        s7 = 23,
        s8 = 24,
        s9 = 25,
        s10 = 26,
        s11 = 27,

        t3 = 28,
        t4 = 29,
        t5 = 30,
        t6 = 31,

        pub fn resolve(self: Alias) Register {
            return @enumFromInt(@intFromEnum(self));
        }
    };

    x0,
    x1,
    x2,
    x3,
    x4,
    x5,
    x6,
    x7,
    x8,
    x9,

    x10,
    x11,
    x12,
    x13,
    x14,
    x15,
    x16,
    x17,
    x18,
    x19,

    x20,
    x21,
    x22,
    x23,
    x24,
    x25,
    x26,
    x27,
    x28,
    x29,

    x30,
    x31,
};

pub const Immediate = i32;

pub const NativeInstruction = union(enum) {
    pub const RType = packed struct {
        opcode: u7,
        rd: Register,
        funct3: u3,
        rs1: Register,
        rs2: Register,
        funct7: u7,
    };

    pub const IType = packed struct {
        opcode: u7,
        rd: Register,
        funct3: u3,
        rs1: Register,
        imm: u12,
    };

    pub const SType = packed struct {
        opcode: u7,
        imm1: u5 = 0,
        funct3: u3,
        rs1: Register,
        rs2: Register,
        imm2: u7 = 0,

        pub fn withImm(s: SType, imm: i12) NativeInstruction {
            var self = s;
            const umm = @as(u12, @bitCast(imm));

            self.imm1 = @as(u5, umm & 0b11111);
            self.imm2 = @as(u7, umm & 0b1111111);

            return NativeInstruction{ .B = self };
        }
    };

    pub const BType = packed struct {
        opcode: u7,
        imm3: u1 = 0, // imm[11]
        imm1: u4 = 0, // imm[4:1]
        funct3: u3,
        rs1: Register,
        rs2: Register,
        imm2: u6 = 0, // imm[10:5]
        imm4: u1 = 0, // imm[12]

        pub fn withImm(b: BType, imm: i13) NativeInstruction {
            var self = b;
            const umm = @as(u13, @bitCast(imm));

            // imm4 // imm3 // imm 2      // imm 1 // skip
            // [0]     [0]  [0 0 0 0 0 0] [0 0 0 0]   0
            self.imm1 = @as(u4, @intCast((umm >> 1) & 0b1111));
            self.imm2 = @as(u6, @intCast((umm >> 5) & 0b111111));
            self.imm3 = @as(u1, @intCast((umm >> 11) & 0b1));
            self.imm4 = @as(u1, @intCast((umm >> 12) & 0b1));

            return NativeInstruction{ .B = self };
        }
    };

    pub const UType = packed struct {
        opcode: u7,
        rd: Register,
        imm: u20,
    };

    pub const JType = packed struct {
        opcode: u7,
        rd: Register,
        imm1: u8 = 0, // imm[19:12]
        imm3: u1 = 0, // imm[11]
        imm2: u10 = 0, // imm[10:1]
        imm4: u1 = 0, // imm[20]

        pub fn withImm(j: JType, imm: i21) NativeInstruction {
            var self = j;
            const umm = @as(u21, @bitCast(imm));

            // imm4 // imm3    // imm 2               // imm 1          // skip
            // [0]     [0]     [0 0 0 0 0 0 0 0 0 0]  [0 0 0 0 0 0 0 0] [0]

            self.imm2 = @as(u10, (umm >> 1) & 0b1111111111);
            self.imm3 = @as(u1, (umm >> 11) & 0b1);
            self.imm1 = @as(u8, (umm >> 12) & 0b11111111);
            self.imm4 = @as(u1, (umm >> 20) & 0b1);

            return NativeInstruction{ .B = self };
        }
    };

    pub fn write(self: NativeInstruction, writer: *std.Io.Writer) !void {
        switch (self) {
            .R => try writer.writeStruct(self.R, .little),
            .I => try writer.writeStruct(self.I, .little),
            .S => try writer.writeStruct(self.S, .little),
            .U => try writer.writeStruct(self.U, .little),
            .B => try writer.writeStruct(self.B, .little),
            .J => try writer.writeStruct(self.J, .little),
        }
    }

    R: RType,
    I: IType,
    S: SType,
    B: BType,
    U: UType,
    J: JType,
};

pub const Operand = union(enum) { Imm };

pub const Instruction = union(enum) {
    /// rd, rs1, imm
    addi: struct { Register, Register, Immediate },
    auipc: struct { Register, Immediate },
    ecall,

    pub fn native(self: Instruction) NativeInstruction {
        return switch (self) {
            .auipc => |i| NativeInstruction{ .U = .{
                .opcode = 0x17,
                .rd = i.@"0",
                .imm = @bitCast(@as(i20, @intCast(i.@"1"))),
            } },
            .addi => |i| NativeInstruction{ .I = .{
                .opcode = 0x13,
                .funct3 = 0x0,
                .rd = i.@"0",
                .rs1 = i.@"1",
                .imm = @bitCast(@as(i12, @intCast(i.@"2"))),
            } },
            .ecall => NativeInstruction{
                .I = .{
                    .opcode = 0x73,
                    .funct3 = 0x0,
                    .rd = .x0,
                    .rs1 = .x0,
                    .imm = 0x0,
                },
            },
        };
    }
};
