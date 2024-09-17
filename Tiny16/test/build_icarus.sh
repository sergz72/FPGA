#! /bin/sh

iverilog -I .. -s tiny16_tb ../tiny16.v ../test.v
