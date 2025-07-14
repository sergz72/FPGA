#! /bin/sh

verilator $* --binary --trace --top test main.v test.v ../picorv32.v
