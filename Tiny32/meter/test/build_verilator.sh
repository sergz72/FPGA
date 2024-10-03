#! /bin/sh

verilator $* -I../.. --binary --trace --top test ../main.v ../test.v ../../tiny32.v
