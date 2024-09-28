#! /bin/sh

verilator $* -I.. --binary --trace --top test ../main.v ../test.v ../../picorv32.v
