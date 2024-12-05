#! /bin/sh

verilator $* -I../../v4 -I.. --binary --trace --top test ../../v4/tiny32.v ../test.v ../main_v4.v ../../../common/div.v
