#! /bin/sh

verilator $* --trace --binary --top uart_fifo_tb ../uart_fifo_tb.v ../uart_fifo.v ../uart1.v ../fifo.v
