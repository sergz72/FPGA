#! /bin/sh

verilator $* --binary --trace --top main_tb ../../common/dds.v ../main.v ../device_handler.v ../main_tb.v
