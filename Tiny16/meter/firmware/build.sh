#! /bin/sh

clang-18 --target=msp430-none-elf -S -I . -O3 -emit-llvm -o a.ll $*
