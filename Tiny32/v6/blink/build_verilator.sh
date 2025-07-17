#! /bin/sh

verilator $* -I.. --binary --trace --top test ../tiny32.v test.v
