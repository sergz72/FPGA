#! /bin/sh

verilator $* --trace-max-array 1000000 --trace-max-width 1000000 --binary --trace --top main_tb main.v ../tiny16.v main_tb.v
