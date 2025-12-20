const std = @import("std");

const BitWidth = enum(u8) { u32 = 0x1, u64 = 0x2 };

pub fn Elf(comptime T: type) type {
    const bitwidth = switch (T) {
        u32 => BitWidth.u32,
        u64 => BitWidth.u64,
        else => @compileError("unknown bit width"),
    };

    return extern struct {
        pub const Ident = extern struct {
            pub const OSABI = enum(u8) {
                NONE = 0x0,
                HPUX = 0x1,
                NETBSD = 0x2,
                GNU = 0x3,
                SOLARIS = 0x6,
                AIX = 0x7,
                IRIX = 0x8,
                FREEBSD = 0x9,
                TRU64 = 0xA,
                MODESTO = 0xB,
                OPENBSD = 0xC,
                OPENVMS = 0xD,
                NSK = 0xE,
                AROS = 0xF,
                FENIXOS = 0x10,
                CLOUDABI = 0x11,
                OPENVOS = 0x12,
                _,
            };

            mag: [4]u8 = [_]u8{ 0x7F, 'E', 'L', 'F' },
            class: BitWidth = bitwidth,
            data: u8 = 0x1,
            version: u8 = 0x1,
            osabi: OSABI,
            abiversion: u8 = 0x0,
            pad: [7]u8 = [_]u8{0} ** 7,
        };

        pub const EType = enum(u16) {
            NONE = 0x0,
            REL = 0x1,
            EXEC = 0x2,
            DYN = 0x3,
            CORE = 0x4,
            _,
        };

        pub const EMachine = enum(u16) {
            NONE = 0x0,
            I386 = 0x3,
            MIPS = 0x8,
            x86_64 = 0x3E,
            RISCV = 0xF3,
            _,
        };

        pub const Section = extern struct {
            pub const Type = enum(u32) {
                NULL = 0x0,
                PROGBITS = 0x1,
                SYMTAB = 0x2,
                STRTAB = 0x3,
                RELA = 0x4,
                HASH = 0x5,
                DYNAMIC = 0x6,
                NOTE = 0x7,
                NOBITS = 0x8,
                REL = 0x9,
                SHLIB = 0xA,
                DYNSYM = 0xB,
                INIT_ARRAY = 0xD,
                FINI_ARRAY = 0xE,
                PREINIT_ARRAY = 0x10,
                GROUP = 0x11,
                SYMTAB_SHNDX = 0x12,
                RELR = 0x13,
                _,
            };

            pub const Flag = struct {
                pub const WRITE = 0x1;
                pub const ALLOC = 0x2;
                pub const EXEC = 0x4;
                pub const MERGE = 0x10;
                pub const STRINGS = 0x20;
                pub const INFO_LINK = 0x40;
                pub const LINK_ORDER = 0x80;
                pub const OS_NONCONFORMING = 0x100;
                pub const GROUP = 0x200;
                pub const TLS = 0x400;
                pub const COMPRESSED = 0x800;
                pub const MASKOS = 0x0ff00000;
                pub const MASKPROC = 0xf0000000;
            };

            pub const NULL = Section{
                .name = 0x0,
                .type = .NULL,
                .flags = 0x0,
                .addr = 0x0,
                .offset = 0x0,
                .size = 0x0,
            };

            pub const Abstract = struct {
                name: []const u8,
                data: []const u8,
                type: Type,
                flags: T,

                addralign: T = 0x1,
                vsize: T = 0x0, // for NOBITS
                symbols: []const Symbol.Abstract = &.{},
            };

            name: u32,
            type: Type,
            flags: T,
            addr: T,
            offset: T,
            size: u32,
            link: u32 = 0x0,
            info: u32 = 0x0,
            addralign: T = 0x1,
            entsize: T = 0x0,
        };

        pub const Symbol = struct {
            pub const Binding = enum(u4) {
                LOCAL = 0x0,
                GLOBAL = 0x1,
                WEAK = 0x2,
                _,
            };

            pub const Type = enum(u4) {
                NOTYPE = 0x0,
                OBJECT = 0x1,
                FUNC = 0x2,
                SECTION = 0x3,
                FILE = 0x4,
                COMMON = 0x5,
                TLS = 0x6,
                _,
            };

            const Sym32 = extern struct {
                name: u32,
                offset: T,
                size: T,
                info: u8,
                other: u8,
                shndx: u16,
            };

            const Sym64 = extern struct {
                name: u32,
                info: u8,
                other: u8,
                shndx: u16,
                offset: T,
                size: T,
            };

            pub const Abstract = struct {
                name: []const u8,
                binding: Binding,
                type: Type,
                offset: T,
                size: T = 0x0,
            };

            pub const Entry = switch (bitwidth) {
                .u32 => Sym32,
                .u64 => Sym64,
            };

            pub const NULL = Entry{
                .name = 0,
                .offset = 0,
                .info = 0,
                .other = 0,
                .shndx = 0,
                .size = 0,
            };
        };

        ident: Ident,
        type: EType,
        machine: EMachine,
        version: u8 = 0x1,
        entry: T,

        phoff: T = 0x0,
        shoff: T,

        flags: u32,
        ehsize: u16 = @sizeOf(@This()),

        phentsize: u16 = 0x0,
        phnum: u16 = 0x0,

        shentsize: u16,
        shnum: u16,
        shstrndx: u16,

        const names = struct {
            pub const strtab = ".strtab";
            pub const shstrtab = ".shstrtab";
            pub const symtab = ".symtab";
        };

        pub fn emit(allocator: std.mem.Allocator, writer: *std.Io.Writer, osabi: Ident.OSABI, machine: EMachine, sections: []const Section.Abstract) !void {
            var shstrtab = try buildStrtab(allocator, sections, true);
            defer shstrtab.deinit(allocator);

            var strtab = try buildStrtab(allocator, sections, false);
            defer strtab.deinit(allocator);

            const symtab = try buildSymtab(allocator, strtab.map, sections, 1); // null
            defer allocator.free(symtab.data);

            const after_headers = @sizeOf(@This()) + @sizeOf(Section) * (sections.len + 4); // null, strtab, shstrtab, symtab

            const section_offsets = try allocator.alloc(T, sections.len + 3);
            defer allocator.free(section_offsets);

            var offset: T = @intCast(after_headers);
            for (sections, 0..) |sect, i| {
                if (sect.type == .NOBITS) continue;
                section_offsets[i] = std.mem.alignForward(T, offset, sect.addralign);
                offset += @intCast(sect.data.len);
            }

            // ... regular sections
            // section string table
            // symbol string table
            // symbol table
            // TODO: rel tables

            const last_offset = if (sections.len == 0) after_headers else section_offsets[sections.len - 1] + sections[sections.len - 1].data.len;
            section_offsets[sections.len] = std.mem.alignForward(T, @intCast(last_offset), @sizeOf(T));
            section_offsets[sections.len + 1] = section_offsets[sections.len] + @as(u32, @intCast(shstrtab.data.len));
            section_offsets[sections.len + 2] = section_offsets[sections.len + 1] + @as(u32, @intCast(strtab.data.len));

            try writer.writeStruct(Elf(T){
                .entry = 0x0,
                .ident = .{
                    .osabi = osabi,
                },
                .flags = 0x0,
                .machine = machine,
                .shoff = @sizeOf(@This()),
                .shentsize = @sizeOf(Section),
                .shnum = @intCast(sections.len + 4),
                .shstrndx = @intCast(sections.len + 1),
                .type = .REL,
            }, .little);

            try writer.writeStruct(Section.NULL, .little);

            for (sections, 0..) |sect, i| {
                try writer.writeStruct(Section{
                    .addr = 0,
                    .name = shstrtab.map.get(sect.name) orelse unreachable,
                    .size = if (sect.type == .NOBITS) sect.vsize else @intCast(sect.data.len),
                    .offset = section_offsets[i],
                    .addralign = sect.addralign,
                    .flags = sect.flags,
                    .type = sect.type,
                }, .little);
            }

            try writer.writeStruct(Section{
                .addr = 0,
                .flags = 0,
                .name = shstrtab.map.get(names.shstrtab) orelse unreachable,
                .size = @intCast(shstrtab.data.len),
                .offset = section_offsets[sections.len],
                .type = .STRTAB,
            }, .little);

            try writer.writeStruct(Section{
                .addr = 0,
                .flags = 0,
                .name = shstrtab.map.get(names.strtab) orelse unreachable,
                .size = @intCast(strtab.data.len),
                .offset = section_offsets[sections.len + 1],
                .type = .STRTAB,
            }, .little);

            try writer.writeStruct(Section{
                .addr = 0,
                .flags = 0,
                .name = shstrtab.map.get(names.symtab) orelse unreachable,
                .size = @intCast(symtab.data.len),
                .offset = section_offsets[sections.len + 2],
                .type = .SYMTAB,
                .info = symtab.nonlocal_start,
                .link = @intCast(sections.len + 2),
                .entsize = @sizeOf(Symbol.Entry),
            }, .little);

            var written: T = @intCast(after_headers);

            for (sections, 0..) |sect, i| {
                for (written..section_offsets[i]) |_| try writer.writeByte(0);
                try writer.writeAll(sect.data);
                written = section_offsets[i] + @as(T, @intCast(sect.data.len));
            }

            const def_sections = [_][]const u8{ shstrtab.data, strtab.data, symtab.data };
            for (def_sections, 0..) |sect, i| {
                for (written..section_offsets[sections.len + i]) |_| try writer.writeByte(0);
                try writer.writeAll(sect);
                written = section_offsets[sections.len + i] + @as(T, @intCast(sect.len));
            }
        }

        pub fn buildSymtab(allocator: std.mem.Allocator, strtab: std.StringHashMapUnmanaged(u32), sections: []const Section.Abstract, section_start: usize) !struct {
            data: []u8,
            nonlocal_start: u32,
        } {
            var acc = std.Io.Writer.Allocating.init(allocator);
            defer acc.deinit();

            const writer = &acc.writer;

            try writer.writeStruct(Symbol.NULL, .little);

            var nonlocal_start: u32 = 1;
            inline for (0..2) |l| {
                const local_only = l == 0;
                for (sections, 0..) |sect, shndx| for (sect.symbols) |sym| {
                    if ((sym.binding == .LOCAL and local_only) or (sym.binding != .LOCAL and !local_only)) {
                        if (local_only) nonlocal_start += 1;
                        try writer.writeStruct(Symbol.Entry{
                            .offset = sym.offset,
                            .info = (@as(u8, @intFromEnum(sym.binding)) << 4) | @as(u8, @intFromEnum(sym.type)),
                            .name = strtab.get(sym.name) orelse unreachable,
                            .other = 0x0,
                            .shndx = @intCast(section_start + shndx),
                            .size = sym.size,
                        }, .little);
                    }
                };
            }

            return .{
                .data = try acc.toOwnedSlice(),
                .nonlocal_start = nonlocal_start,
            };
        }

        pub fn buildStrtab(
            allocator: std.mem.Allocator,
            sections: []const Section.Abstract,
            is_shstrtab: bool,
        ) !struct {
            data: []u8,
            map: std.StringHashMapUnmanaged(u32),

            pub fn deinit(self: *@This(), ally: std.mem.Allocator) void {
                ally.free(self.data);
                self.map.deinit(ally);
            }
        } {
            var acc = std.Io.Writer.Allocating.init(allocator);
            defer acc.deinit();
            const writer = &acc.writer;

            var map = std.StringHashMapUnmanaged(u32).empty;

            try writer.writeByte(0);

            var offset: u32 = 1;

            if (is_shstrtab) {
                const essentials = [_][]const u8{ names.shstrtab, names.strtab, names.symtab };

                for (essentials) |name| {
                    try map.put(allocator, name, offset);
                    try writer.writeAll(name);
                    try writer.writeByte(0);
                    offset += @intCast(name.len + 1);
                }

                for (sections) |sect| {
                    const gop = try map.getOrPut(allocator, sect.name);
                    if (gop.found_existing) continue;

                    try map.put(allocator, sect.name, offset);
                    try writer.writeAll(sect.name);
                    try writer.writeByte(0);
                    offset += @intCast(sect.name.len + 1);
                }
            } else {
                for (sections) |sect| {
                    for (sect.symbols) |sym| {
                        const gop = try map.getOrPut(allocator, sym.name);
                        if (gop.found_existing) continue;

                        try map.put(allocator, sym.name, offset);
                        try writer.writeAll(sym.name);
                        try writer.writeByte(0);
                        offset += @intCast(sym.name.len + 1);
                    }
                }
            }

            return .{
                .data = try acc.toOwnedSlice(),
                .map = map,
            };
        }
    };
}
