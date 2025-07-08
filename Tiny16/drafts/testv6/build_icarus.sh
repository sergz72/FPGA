#! /bin/sh

iverilog $* -I .. -s main_tb main.v ../tiny16.v main_tb.v
