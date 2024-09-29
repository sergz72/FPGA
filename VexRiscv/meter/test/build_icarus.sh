#! /bin/sh

iverilog -I .. -s test ../main.v ../test.v ../../VexRiscv.v
