#! /bin/sh

verilator $* -I.. --binary --trace --top test ../tiny32.v test.v ../../../common/uart1.v ../../../common/uart_fifo.v ../../../common/fifo.v
