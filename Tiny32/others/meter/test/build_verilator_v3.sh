#! /bin/sh

cp ../../*.mem .

verilator $* -I.. -I../../v3 --binary --trace --top test ../main.v ../test.v ../../v3/tiny32.v ../../../common/fifo.v ../../../common/uart1.v ../../../common/uart_fifo.v \
../../../common/div.v ../../../common/timer.v ../../../common/time_counter.v
