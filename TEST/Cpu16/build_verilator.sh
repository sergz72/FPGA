#! /bin/sh

verilator --binary --trace --top cpu16_tb --trace cpu16.v test.v alu.v
