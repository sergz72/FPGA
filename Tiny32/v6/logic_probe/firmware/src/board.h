#ifndef _BOARD_H
#define _BOARD_H

#include <cpu.h>

#define PORT_ADDRESS 0
#define UART_DATA_ADDRESS   0x10000000
#define SPI_LCD_ADDRESS     0x20000000
#define TIMER_ADDRESS       0x30000000
#define LOGIC_PROBE_ADDRESS 0x40000000
#define UART_TX_FIFO_FULL  1
#define UART_RX_FIFO_EMPTY 2
#define SPI_LCD_FIFO_FULL  4
#define SPI_LCD_DONE       8

#define MS_VALUE 1000

#define ST7789_MADCTL_VALUE (ST7789_MADCTL_MX | ST7789_MADCTL_MV)
#define LCD_WIDTH  240
#define LCD_HEIGHT 135

#define NO_ST7789_RESET

void delayms(unsigned int ms);

#endif