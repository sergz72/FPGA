#! /bin/sh

verilator $* -I../../v5 --binary --trace --top tiny32_tb ../tiny32.v test.v ../../../common/div.v
