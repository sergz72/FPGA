#! /bin/sh

iverilog $* -s main_tb tiny16.v main.v test_main.v
