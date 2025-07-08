#! /bin/sh

verilator $* -I../../v5 --binary --trace --top tiny32_tb ../../v5/tiny32.v test_v4.v ../../../common/div.v
