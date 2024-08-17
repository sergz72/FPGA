#! /bin/sh

verilator --binary -I../.. --trace --top ks0108_tb test_ks.v main.v ../../cpu16.v ../../alu.v ../../../common/register_file.v ../../../common/frequency_counter.v ../../../common/logic_probe_led.v
