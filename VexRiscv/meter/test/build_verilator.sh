#! /bin/sh

/opt/verilator/bin/verilator $* -I.. --binary --trace --top test ../main.v ../test.v ../../VexRiscv.v
