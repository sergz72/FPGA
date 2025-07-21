#! /bin/sh

iverilog -I ../.. -s test ../main.v ../test.v ../../tiny32.v
