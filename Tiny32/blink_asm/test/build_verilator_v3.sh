#! /bin/sh

verilator $* -I.. -I../../v3 --binary --trace --top test ../main.v ../test.v ../../v3/tiny32.v ../../../common/div.v ../../../common/uart1.v
