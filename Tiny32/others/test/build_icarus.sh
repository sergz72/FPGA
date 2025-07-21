#! /bin/sh

iverilog -I .. -s tiny32_tb ../tiny32.v ../test.v
