#! /bin/sh

/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-gcc -march=rv32im -specs=nosys.specs -specs=nano.specs -nodefaultlibs -nostdlib -nostartfiles -o asm/a.out -T ldscript.ld start.S $*
retVal=$?
if [ $retVal -ne 0 ]; then
  exit $retVal
fi

cd asm

rm data*.hex

/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-objdump -d a.out > a.out.asmdump
/opt2/xpack-riscv-none-elf-gcc-14.2.0-3/bin/riscv-none-elf-objdump -s a.out > a.out.datadump
DumpToHex 2 a.out.asmdump a.out.datadump
retVal=$?
if [ $retVal -ne 0 ]; then
  exit $retVal
fi

cd ..
