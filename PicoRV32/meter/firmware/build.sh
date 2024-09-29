#! /bin/sh

../build_picorv32_gcc.sh src/main.c
../tohex.sh a.out
