#ifndef _BOARD_H
#define _BOARD_H

#include <cpu.h>

#define PORT_ADDRESS          0
#define UART_DATA_ADDRESS     0x20000000
#define SPI_LCD_ADDRESS       0x40000000
#define TIMER_ADDRESS         0x60000000
#define LOGIC_PROBE_ADDRESS   0x80000000
#define DAC1_ADDRESS          0xA0000000
#define DAC2_ADDRESS          0xC0000000
#define UART_TX_FIFO_FULL     1
#define UART_RX_FIFO_EMPTY    2
#define SPI_LCD_FIFO_FULL     4
#define SPI_LCD_DONE          8
#define LED                   1
#define PROBE_INTERRUPT_CLEAR 2
#define PROBE_NRESET          4

#define MS_VALUE 1024

#define ST7789_MADCTL_VALUE (ST7789_MADCTL_MX | ST7789_MADCTL_MV)
#define LCD_WIDTH  240
#define LCD_HEIGHT 135

#define NO_ST7789_RESET

#define DEFAULT_DACH_VOLTAGE 24
#define DEFAULT_DACL_VOLTAGE 4

#define COUNTERS_MAX 1000

#define BUTTON1_BIT 0x20
#define BUTTON2_BIT 0x10

#define DISPLAY_MAX_COLUMNS    13
#define DISPLAY_MAX_ROWS       6
#define DISPLAY_MAX_RECTANGLES 4

#define TIMER_EVENT_FREQUENCY 10

extern unsigned int counter_low, counter_high, counter_z;
extern unsigned int counter_freq_low, counter_freq_high, counter_freq_rs;

void delayms(unsigned int ms);

void set_l_voltage(unsigned int value);
void set_h_voltage(unsigned int value);

#endif