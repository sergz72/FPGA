#! /bin/sh

verilator $* -I.. --binary --trace --top test ../main.v ../test.v ../../picorv32.v ../../../common/uart1.v ../../../common/uart_fifo.v ../../../common/fifo.v ../../../common/timer.v ../../../common/time_counter.v
