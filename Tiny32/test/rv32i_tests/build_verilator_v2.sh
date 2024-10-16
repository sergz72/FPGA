#! /bin/sh

cp ../../v2/*.mem .

verilator $* -I../../v2 --binary --trace --top tiny32_tb ../../v2/tiny32.v test_v2.v ../../../common/div.v
