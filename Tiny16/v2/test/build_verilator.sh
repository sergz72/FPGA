#! /bin/sh

verilator $* -I.. --binary --trace --top tiny16_tb ../tiny16.v ../test.v
