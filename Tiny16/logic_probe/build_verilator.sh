#! /bin/sh

verilator $* -I.. --binary --trace --top main_tb \
main.v \
../tiny16.v \
main_tb.v \
../../common/logic_probe16.v \
../../common/ws2812b.v
