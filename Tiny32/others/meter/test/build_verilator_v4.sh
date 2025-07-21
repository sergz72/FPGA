#! /bin/sh

verilator $* -I.. -I../../v4 --binary --trace --top test ../main_v4.v ../test.v ../../v4/tiny32.v ../../../common/fifo.v ../../../common/uart1.v ../../../common/uart_fifo.v \
../../../common/div.v ../../../common/timer.v ../../../common/time_counter.v
