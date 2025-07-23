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

void set_l_voltage(unsigned int value)
{
  out(value, DAC1_ADDRESS);
}

void set_h_voltage(unsigned int value)
{
  out(value, DAC2_ADDRESS);
}
