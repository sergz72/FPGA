#! /bin/sh

/opt/FPGA/oss-cad-suite/bin/verilator $* --binary --trace --top logic_probe_spi_dac_tb ../logic_probe_spi_dac.v logic_probe_spi_dac_tb.v
