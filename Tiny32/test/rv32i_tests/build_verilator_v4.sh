#! /bin/sh

verilator $* -I../../v4 --binary --trace --top tiny32_tb ../../v4/tiny32.v test_v4.v ../../../common/div.v
