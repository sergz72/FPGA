#! /bin/sh

verilator $* --binary --trace --top test ../VexRiscv.v main.v test.v ../../../common/timer.v
