#! /bin/sh

rm data*.hex

/opt2/riscv32i/bin/riscv32-unknown-elf-objdump -d $1 > $1.asmdump
/opt2/riscv32i/bin/riscv32-unknown-elf-objdump -s $1 > $1.datadump
DumpToHex 2 $1.asmdump $1.datadump
