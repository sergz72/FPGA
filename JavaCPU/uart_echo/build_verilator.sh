#! /bin/sh

verilator $* --binary --trace --top main_tb main.v ../java_cpu.v main_tb.v ../../common/timer.v ../../common/uart1.v
