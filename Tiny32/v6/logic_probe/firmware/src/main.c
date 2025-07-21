#include "board.h"
#include <lcd_st7789.h>

__attribute__((naked)) int main(void)
{
  LcdInit(ST7789_MADCTL_VALUE);

  while (1)
    wfi();

  /*unsigned int state = 1;
  while (1)
  {
    wfi();
    uart_handler();
    state ^= 1;
    out(state, LED_ADDRESS);
  }*/
}
