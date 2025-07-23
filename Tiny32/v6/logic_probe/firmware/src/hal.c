#include "board.h"
#include "ui.h"
#include <stdio.h>

static unsigned int l_voltage, h_voltage;

static void uart_send(unsigned int c)
{
  while (1)
  {
    unsigned int uart_status = in(PORT_ADDRESS);
    if (!(uart_status & UART_TX_FIFO_FULL))
    {
      out(c, UART_DATA_ADDRESS);
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
  unsigned int uart_data;

  uart_status = in(PORT_ADDRESS);
  if (uart_status & UART_RX_FIFO_EMPTY)
    return EOF;
  uart_data = in(UART_DATA_ADDRESS);
  return (int)uart_data;
}

void delayms(unsigned int ms)
{
  out(MS_VALUE * ms, TIMER_ADDRESS);
  wfi();
}

void set_l_voltage(unsigned int value)
{
  out(value, DAC1_ADDRESS);
  ul_changed_to = value;
  l_voltage = value;
}

void set_h_voltage(unsigned int value)
{
  out(value, DAC2_ADDRESS);
  uh_changed_to = value;
  h_voltage = value;
}

unsigned int get_l_voltage(void)
{
  return l_voltage;
}

unsigned int get_h_voltage(void)
{
  return h_voltage;
}

void pwm_set_frequency_and_duty(unsigned int frequency, unsigned int duty)
{
  unsigned int period = PWM_CLOCK_FREQUENCY / frequency;
  if (!period)
    period = 1;
  if (duty > 99)
    duty = 99;
  out(period - 1, PWM_ADDRESS);
  out(period * duty / 100, PWM_ADDRESS + 1);
}