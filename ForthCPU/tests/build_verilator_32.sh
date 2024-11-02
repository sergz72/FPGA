#! /bin/sh

verilator $* -DWIDTH=32 --binary --trace --top main_tb main.v ../forth_cpu.v main_tb.v
