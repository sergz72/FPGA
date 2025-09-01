#! /bin/sh

verilator $* -I../../common --binary --trace --top test main.v test.v ../picorv32.v ../../common/qspi_rom_controller.v ../../common/qspi_rom_emulator.v
