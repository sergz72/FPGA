#! /bin/sh

verilator $* --binary --trace --top div_tb ../div.v ../div_tb.v
