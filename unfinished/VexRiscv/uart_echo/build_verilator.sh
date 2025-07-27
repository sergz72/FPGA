#! /bin/sh

verilator $* --binary --trace --top test ../VexRiscv.v main.v test.v ../../../common/timer.v ../../../common/uart1.v ../../../common/uart_fifo.v ../../../common/fifo.v
