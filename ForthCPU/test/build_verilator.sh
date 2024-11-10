#! /bin/sh

verilator $* -I.. --binary --trace --top main_tb main.v ../forth_cpu.v main_tb.v ../../common/uart1.v ../../common/timer.v
