#! /bin/sh

verilator $* -I../../v3 -I.. --binary --trace --top test ../../v3/tiny32.v ../test.v ../main.v ../../../common/div.v
