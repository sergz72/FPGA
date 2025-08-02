#ifndef _CPU_H
#define _CPU_H

#define PORT_ADDRESS ((volatile unsigned int*)0x30000000)
#define UART_DATA_ADDRESS ((volatile unsigned char*)0x40000000)
#define UART_CONTROL_ADDRESS ((volatile unsigned int*)0x50000000)
#define UART_TX_FIFO_FULL 1
#define UART_RX_FIFO_EMPTY 2

unsigned int wfi(void);
unsigned int getq(void);
unsigned int timer(unsigned int value);
unsigned int get_cycles(void);
unsigned int get_time(void);
unsigned int get_instret(void);

#endif
