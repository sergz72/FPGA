#! /bin/sh

verilator $* --binary --trace --top main_tb ../main_tb.v ../main.v ../../../common/dds.v ../../../common/frequency_counter.v ../../../common/pwm.v
