#! /bin/sh

verilator --binary --trace --top spi_lcd_tb ../spi_lcd.v ../spi_lcd_tb.v ../fifo.v
