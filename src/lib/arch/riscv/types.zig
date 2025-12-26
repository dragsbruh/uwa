const Register = @import("registers.zig").Register;

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
