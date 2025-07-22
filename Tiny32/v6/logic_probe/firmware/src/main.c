#include "board.h"
#include <lcd_st7789.h>
#include "font16.h"
#include "display.h"
#include "ui.h"

unsigned int counter_low, counter_high, counter_z;
unsigned int counter_freq_low, counter_freq_high, counter_freq_rs;

// timer interrupt
void __attribute__((interrupt("machine"))) isr1(void)
{
}

// logic probe interrupt
void __attribute__((interrupt("machine"))) isr2(void)
{

}

void DrawChar(unsigned int x, unsigned int y, unsigned int ch, unsigned int text_color, unsigned int bk_color)
{
  SetWindow(x, y, x + FONT_WIDTH - 1, y + FONT_HEIGHT - 1);
  font16_symbols[ch](text_color, bk_color);
}

__attribute__((naked)) int main(void)
{
  counter_low = counter_high = counter_z = 0;
  counter_freq_low = counter_freq_high = counter_freq_rs = 0;

  unsigned int port_state = 0;

  out(port_state, PORT_ADDRESS);

  /*LcdInit(ST7789_MADCTL_VALUE);
  DrawChar(0, 0, 0, YELLOW_COLOR, BLACK_COLOR);
  DrawChar(16, 0, 9, YELLOW_COLOR, BLACK_COLOR);
  DrawChar(32, 0, 10, YELLOW_COLOR, BLACK_COLOR);
  DrawChar(48, 0, 11, YELLOW_COLOR, BLACK_COLOR);
  DrawChar(64, 0, 16, YELLOW_COLOR, BLACK_COLOR);*/
  UI_Init();

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
