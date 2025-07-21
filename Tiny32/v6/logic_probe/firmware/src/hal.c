#include "board.h"

/*static void uart_send(unsigned int c)
{
  while (1)
  {
    unsigned int uart_status = in(UART_CONTROL_ADDRESS);
    if (!(uart_status & UART_TX_FIFO_FULL))
    {
      out(c, UART_DATA_ADDRESS);
      return;
    }
  }
}

static void uart_handler(void)
{
  unsigned int uart_status;
  unsigned int uart_data;

  while (1)
  {
    uart_status = in(UART_CONTROL_ADDRESS);
    if (uart_status & UART_RX_FIFO_EMPTY)
      return;
    uart_data = in(UART_DATA_ADDRESS);
    uart_send(uart_data);
  }
}*/

void delayms(unsigned int ms)
{
  out(MS_VALUE * ms, TIMER_ADDRESS);
  wfi();
}

void ST7789_WriteBytes(unsigned int flags, unsigned char *data, unsigned int size)
{
  while (size)
  {
    if (in(PORT_ADDRESS) & SPI_LCD_FIFO_FULL)
      continue;
    unsigned int v = *data++;
    out(v|flags, SPI_LCD_ADDRESS);
    size--;
  }
}
