#! /bin/sh

verilator $* -I.. --binary --trace --top main_tb main.v ../tiny16.v main_tb.v
