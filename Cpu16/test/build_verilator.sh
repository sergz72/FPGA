#! /bin/sh

verilator -I.. --binary --trace --top cpu16_tb ../cpu16.v ../test.v ../alu.v ../register_file.v
