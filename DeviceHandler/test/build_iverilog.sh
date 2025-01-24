#! /bin/sh

iverilog -s main_tb ../../common/dds.v ../main.v ../device_handler.v ../main_tb.v ../led_handler.v
