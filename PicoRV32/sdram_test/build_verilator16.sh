#! /bin/sh

verilator $* --binary --trace --top test16 main16.v test16.v ../picorv32.v \
+define+GEN16=1 \
../../common/uart1.v ../../common/uart_fifo.v ../../common/fifo.v \
../../common/sdram_controller_16_to_32.v ../../common/sdram_emulator.sv
