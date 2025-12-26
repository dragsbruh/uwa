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
