#include "board.h"
#include <lcd_st7789.h>

void __attribute__((interrupt("machine"))) isr1(void)
{
}

void __attribute__((interrupt("machine"))) isr2(void)
{

}

__attribute__((naked)) int main(void)
{
  unsigned int port_state = 0;

  out(port_state, PORT_ADDRESS);

  LcdInit(ST7789_MADCTL_VALUE);

  while (1)
    wfi();

  /*while (1)
  {
    wfi();
    uart_handler();
    state ^= 1;
    out(state, LED_ADDRESS);
  }*/
}
