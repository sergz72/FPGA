#! /bin/sh

/opt2/riscv32i/bin/riscv32-unknown-elf-gcc -specs=nosys.specs -specs=nano.specs -nodefaultlibs -nostdlib -nostartfiles -O3 -T pico32rv.ld start.S $*
