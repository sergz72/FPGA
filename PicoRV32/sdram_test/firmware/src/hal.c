#include "board.h"
#include <stdio.h>

static void uart_send(unsigned char c)
{
  while (1)
  {
    unsigned int uart_status = *UART_CONTROL_ADDRESS;
    if (!(uart_status & UART_TX_FIFO_FULL))
    {
      *UART_DATA_ADDRESS = c;
      return;
    }
  }
}

void puts_(const char *s)
{
  while (*s)
    uart_send(*s++);
}

int getch_(void)
{
  unsigned int uart_status;
  unsigned char uart_data;

  uart_status = *UART_CONTROL_ADDRESS;
  if (uart_status & UART_RX_FIFO_EMPTY)
    return EOF;
  uart_data = *UART_DATA_ADDRESS;
  return (int)uart_data;
}
