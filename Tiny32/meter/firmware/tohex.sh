#! /bin/sh

rm asm/*data*.hex

/opt2/riscv32i/bin/riscv32-unknown-elf-objdump -d $1 > asm/$1.asmdump
/opt2/riscv32i/bin/riscv32-unknown-elf-objdump -s $1 > asm/$1.datadump

cd asm

DumpToHex 2 $1.asmdump $1.datadump

cd ..
