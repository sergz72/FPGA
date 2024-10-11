#ifndef _BOARD_H
#define _BOARD_H

#ifndef NULL
#define NULL 0
#endif

typedef unsigned long long int uint64_t;

#define LED_ADDRESS ((volatile char*)0xF8000000)
#define UART_CONTROL_ADDRESS ((volatile unsigned int*)0xF0000000)
#define UART_DATA_ADDRESS ((volatile unsigned char*)0xE8000000)
#define UART_TX_FIFO_FULL 1
#define UART_RX_FIFO_EMPTY 2

#define MAX_COMMAND 128
#define MAX_MEASUREMENT_NO 10

void delay(unsigned int);
void delayms(unsigned int);
void lcd_init(void);
int I2CCheck(int idx, int device_id);
void SCL_HIGH(int);
void SCL_LOW(int);
void SDA_HIGH(int);
void SDA_LOW(int);
int SDA_IN(int);
int SCL_IN(int);

void _wfi(void);

#define MAX_SHELL_COMMANDS 30
#define MAX_SHELL_COMMAND_PARAMETERS 10
#define MAX_SHELL_COMMAND_PARAMETER_LENGTH 50
#define SHELL_HISTORY_SIZE 20
#define SHELL_HISTORY_ITEM_LENGTH 100

#define I2C_SOFT
#define i2c_dly delay(5) // 100 khz

#define I2C_TIMEOUT 0xFFFFFFFF

#define DRAW_TEXT_MAX 20

#define SSD1306_128_64
#define LCD_ORIENTATION LCD_ORIENTATION_LANDSCAPE
#define LCD_PRINTF_BUFFER_LENGTH 20
#define USE_MYVSPRINTF

#define SI5351_XTAL_FREQ 25000000
#define SI5351_CHANNELS 4

#include "keyboard.h"
#include <lcd_ssd1306.h>

#endif
