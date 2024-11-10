#! /bin/sh

verilator $* -I.. --binary --trace --top main_tb main_blink_hard_delay.v ../forth_cpu.v main_blink_hard_delay_tb.v ../../common/timer.v
