const wrappers = @import("wrappers.zig");
const relocations = @import("relocations.zig");

const Register = @import("registers.zig").Register;
const Spec = @import("../spec.zig").Spec(Register, null);

pub const addi = Spec{
    .name = "addi",
    .operands = &.{ .register, .register, .immediate },
    .fun = &wrappers.addi,
    .constraint = .{
        .immediate = .{
            .bits = 12,
            .signed = true,
        },
    },
    .relocation = .{
        .absolute = relocations.LO12_I,
        .pc_relative = relocations.PCREL_LO12_I,
    },
};

pub const auipc = Spec{
    .name = "auipc",
    .operands = &.{ .register, .immediate },
    .fun = &wrappers.auipc,
    .constraint = .{
        .immediate = .{
            .bits = 20,
            .signed = true,
        },
    },
    .relocation = .{
        .absolute = relocations.HI20,
        .pc_relative = relocations.PCREL_HI20,
    },
};

pub const ecall = Spec{
    .name = "ecall",
    .operands = &.{},
    .fun = &wrappers.ecall,
    .constraint = .{}, // missing = null = constraint is not used
    .relocation = .{},
};
