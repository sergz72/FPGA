#ifndef BOARD_H
#define BOARD_H

#include <cpu.h>

#ifndef NULL
#define NULL 0
#endif

#define SDRAM_ADDRESS ((volatile unsigned int*)0x60000000)
#define SDRAM_SIZE (1<<21)
#define LED1 1
#define LED2 2

#define PRINTF_BUFFER_LENGTH 200
#define USE_MYVSPRINTF

#define MAX_SHELL_COMMANDS 20
#define MAX_SHELL_COMMAND_PARAMETERS 5
#define MAX_SHELL_COMMAND_PARAMETER_LENGTH 50
#define SHELL_HISTORY_SIZE 10
#define SHELL_HISTORY_ITEM_LENGTH 100

int getch_(void);

#endif //BOARD_H
