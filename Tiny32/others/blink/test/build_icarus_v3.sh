#! /bin/sh

iverilog $* -I ../../v3 -I .. -s test ../../v3/tiny32.v ../test.v ../main.v ../../../common/div.v
