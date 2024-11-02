#! /bin/sh

verilator $* -DWIDTH=32 --binary --trace -I.. --top main_tb main.v ../forth_cpu.v main_tb.v
