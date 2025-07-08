#! /bin/sh

verilator $* -I../../v5 -I.. --binary --trace --top test ../../v5/tiny32.v ../test.v ../main_v4.v ../../../common/div.v
