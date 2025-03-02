//Copyright (C)2014-2025 GOWIN Semiconductor Corporation.
//All rights reserved.
//File Title: Timing Constraints file
//Tool Version: V1.9.11 
//Created Time: 2025-02-28 21:41:16
create_clock -name clk -period 37.037 -waveform {0 18.518} [get_ports {clk}]
create_clock -name clk_sys -period 7.407 -waveform {0 2.646} [get_nets {clk_sys}]
