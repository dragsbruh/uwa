#!/bin/sh

set -eou pipefail

mkdir _build -p

zig build

./zig-out/bin/uwa > _build/obj.o
riscv32-elf-ld _build/obj.o -o _build/exe
riscv32-elf-objdump -D _build/exe > _build/exe_disasm.s
riscv32-elf-objdump -D _build/obj.o > _build/obj_disasm.s
