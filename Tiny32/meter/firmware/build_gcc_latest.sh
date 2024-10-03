#! /bin/sh

/opt2/riscv32i_latest/bin/riscv32-unknown-elf-gcc -specs=nosys.specs -specs=nano.specs -nodefaultlibs -nostdlib -nostartfiles -O3 -T ldscript.ld -o asm/a.out src/start.S $*
