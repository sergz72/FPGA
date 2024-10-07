#! /bin/sh

iverilog -I .. -s test ../main.v ../test.v ../../../common/uart1.v ../../../common/uart_fifo.v ../../../common/fifo.v ../../VexRiscv.v
