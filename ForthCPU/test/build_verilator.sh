#! /bin/sh

verilator $* --binary --trace --top main_tb main.v ../forth_cpu.v main_tb.v
