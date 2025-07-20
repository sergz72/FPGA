#! /bin/sh

./build_gcc.sh src/main.c ../../start.S
./tohex.sh a.out
