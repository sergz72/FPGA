#! /bin/sh

verilator $* -I../../v3 --binary --trace --top tiny32_tb ../../v3/tiny32.v test.v ../../../common/div.v
