#! /bin/sh

cp ../../*.mem .

verilator $* -I../.. --binary --trace --top tiny32_tb ../../tiny32.v test.v
