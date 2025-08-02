#! /bin/sh

rm ../asm/*data*.hex

cp cmake-build-release-riscv-xpack-14/PicoRV32_sdram_test.elf ../asm/out.elf

cd ../asm

/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-objdump -d out.elf > out.asmdump
/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-objdump -s out.elf > out.datadump

DumpToHex 2 out.asmdump out.datadump
