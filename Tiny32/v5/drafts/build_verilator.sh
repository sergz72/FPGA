#! /bin/sh

verilator $* --binary --trace --top tiny32_tb tiny32.v test.v
