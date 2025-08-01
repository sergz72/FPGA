#! /bin/sh

/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-gcc -march=rv32im -specs=nosys.specs -specs=nano.specs -nodefaultlibs -nostdlib -nostartfiles -O3 -T ldscript.ld -o ../asm/a.out start.S $*
