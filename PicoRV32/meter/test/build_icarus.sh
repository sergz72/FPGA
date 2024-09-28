#! /bin/sh

iverilog -I .. -s test ../main.v ../test.v ../../picorv32.v
