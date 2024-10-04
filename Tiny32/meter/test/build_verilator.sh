#! /bin/sh

cp ../../*.mem .

verilator $* -I.. --binary --trace --top test ../main.v ../test.v ../../tiny32.v
