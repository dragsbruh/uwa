pub const elf = @import("elf.zig");
pub const arch = @import("arch/root.zig");

pub const Elf32 = elf.Elf(u32);
pub const Elf64 = elf.Elf(u64);
