#! /bin/sh

verilator $* -I../v6 --binary --trace --top main_tb main.v ../v6/tiny16.v main_tb.v
