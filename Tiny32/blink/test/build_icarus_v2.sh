#! /bin/sh

cp ../../v2/*.mem .

iverilog $* -I ../../v2 -I .. -s test ../../v2/tiny32.v ../test.v ../main.v ../../../common/div.v
