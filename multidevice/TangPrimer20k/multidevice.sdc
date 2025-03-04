//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11 
//Created Time: 2025-03-03 18:46:30
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_clock -name freq_in1 -period 3.333 -waveform {0 1.667} [get_ports {freq_in[1]}]
create_clock -name freq_in0 -period 3.333 -waveform {0 1.667} [get_ports {freq_in[0]}]
create_clock -name clk_dds -period 3.367 -waveform {0 1.683} [get_nets {clk_dds}]
create_clock -name clk_pwm -period 13.468 -waveform {0 6.734} [get_nets {clk_pwm}]
