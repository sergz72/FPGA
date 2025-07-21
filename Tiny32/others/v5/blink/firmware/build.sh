#! /bin/sh

./build_gcc.sh src/main.c src/start.S
./tohex.sh a.out
