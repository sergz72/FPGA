#! /bin/sh

verilator $* -I../../v3 --binary --trace --top tiny32_tb ../../v3/tiny32.v test_v3.v ../../../common/div.v ../../v3/instruction_decoder.v
