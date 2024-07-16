#! /bin/sh

iverilog -I .. -s cpu16_tb ../cpu16.v ../test.v ../alu.v ../register_file.v
