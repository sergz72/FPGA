#! /bin/sh

verilator $* --binary --trace --top main_tb main.v tiny16.v test_main.v
