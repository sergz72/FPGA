#! /bin/sh

/opt2/riscv32i/bin/riscv32-unknown-elf-gcc -march=rv32im -specs=nosys.specs -specs=nano.specs -nodefaultlibs -nostdlib -nostartfiles -o asm/a.out -T ldscript.ld start.S $*

cd asm

rm data*.hex

/opt2/riscv32i/bin/riscv32-unknown-elf-objdump -d a.out > a.out.asmdump
/opt2/riscv32i/bin/riscv32-unknown-elf-objdump -s a.out > a.out.datadump
DumpToHex 2 a.out.asmdump a.out.datadump

cd ..
