#! /bin/sh

verilator $* --binary --trace --top top main.v top.v ../picorv32.v \
../../common/uart1.v ../../common/uart_fifo.v ../../common/fifo.v \
../../common/hyperram_controller.v
