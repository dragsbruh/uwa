const std = @import("std");

pub const Register = enum(u5) {
    pub const zero = Register.x0;
    pub const ra = Register.x1;
    pub const sp = Register.x2;
    pub const gp = Register.x3;
    pub const tp = Register.x4;
    pub const t0 = Register.x5;
    pub const t1 = Register.x6;
    pub const t2 = Register.x7;
    pub const s0 = Register.x8;
    pub const s1 = Register.x9;
    pub const a0 = Register.x10;
    pub const a1 = Register.x11;
    pub const a2 = Register.x12;
    pub const a3 = Register.x13;
    pub const a4 = Register.x14;
    pub const a5 = Register.x15;
    pub const a6 = Register.x16;
    pub const a7 = Register.x17;
    pub const s2 = Register.x18;
    pub const s3 = Register.x19;
    pub const s4 = Register.x20;
    pub const s5 = Register.x21;
    pub const s6 = Register.x22;
    pub const s7 = Register.x23;
    pub const s8 = Register.x24;
    pub const s9 = Register.x25;
    pub const s10 = Register.x26;
    pub const s11 = Register.x27;
    pub const t3 = Register.x28;
    pub const t4 = Register.x29;
    pub const t5 = Register.x30;
    pub const t6 = Register.x31;

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

    pub fn withImm(s: SType, imm: i12) SType {
        var self = s;
        const umm = @as(u12, @bitCast(imm));

        self.imm1 = @as(u5, umm & 0b11111);
        self.imm2 = @as(u7, umm & 0b1111111);

        return self;
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

    pub fn withImm(b: BType, imm: i13) BType {
        var self = b;
        const umm = @as(u13, @bitCast(imm));

        // imm4 // imm3 // imm 2      // imm 1 // skip
        // [0]     [0]  [0 0 0 0 0 0] [0 0 0 0]   0
        self.imm1 = @as(u4, @intCast((umm >> 1) & 0b1111));
        self.imm2 = @as(u6, @intCast((umm >> 5) & 0b111111));
        self.imm3 = @as(u1, @intCast((umm >> 11) & 0b1));
        self.imm4 = @as(u1, @intCast((umm >> 12) & 0b1));

        return self;
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

    pub fn withImm(j: JType, imm: i21) JType {
        var self = j;
        const umm = @as(u21, @bitCast(imm));

        // imm4 // imm3    // imm 2               // imm 1          // skip
        // [0]     [0]     [0 0 0 0 0 0 0 0 0 0]  [0 0 0 0 0 0 0 0] [0]

        self.imm2 = @as(u10, (umm >> 1) & 0b1111111111);
        self.imm3 = @as(u1, (umm >> 11) & 0b1);
        self.imm1 = @as(u8, (umm >> 12) & 0b11111111);
        self.imm4 = @as(u1, (umm >> 20) & 0b1);

        return self;
    }
};

pub const encoder = struct {
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
};
