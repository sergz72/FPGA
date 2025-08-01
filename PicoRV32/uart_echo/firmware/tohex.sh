#! /bin/sh

cd ../asm

rm *data*.hex

/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-objdump -d $1 > $1.asmdump
/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-objdump -s $1 > $1.datadump

DumpToHex 2 $1.asmdump $1.datadump
