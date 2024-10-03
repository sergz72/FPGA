#! /bin/sh

verilator $* -I.. --binary --trace --top tiny32_tb ../tiny32.v ../test_rv32i_tests.v
