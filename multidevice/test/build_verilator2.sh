#! /bin/sh

verilator $* --binary --trace --top main2_tb ../main2_tb.v ../main2.v ../../common/dds.v ../../common/frequency_counter.v ../../common/pwm2.v
