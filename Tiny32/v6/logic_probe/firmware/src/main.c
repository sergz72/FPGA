#include "board.h"
#include <lcd_st7789.h>
#include "font16.h"
#include "display.h"
#include "ui.h"

unsigned int counter_low, counter_high, counter_z;
unsigned int counter_freq_low, counter_freq_high, counter_freq_rs;
volatile unsigned int probe_interrupt;

// timer interrupt
void __attribute__((interrupt("machine"))) isr1(void)
{
}

// logic probe interrupt
void __attribute__((interrupt("machine"))) isr2(void)
{
  probe_interrupt = 1;
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
  probe_interrupt = 0;

  unsigned int led_state = 0;
  unsigned int cnt_led = 0;

  out(0, PORT_ADDRESS);

  UI_Init();

  out(PROBE_NRESET, PORT_ADDRESS);

  while (1)
  {
    while (!probe_interrupt)
      ;
    probe_interrupt = 0;
    unsigned int address = LOGIC_PROBE_ADDRESS;
    counter_low = in(address++);
    counter_z = in(address++);
    counter_freq_low = in(address++);
    counter_freq_high = in(address++);
    counter_freq_rs = in(address);
    unsigned int port_state = PROBE_NRESET | PROBE_INTERRUPT_CLEAR | led_state;
    out(port_state, PORT_ADDRESS);
    port_state = PROBE_NRESET | led_state;
    out(port_state, PORT_ADDRESS);
    counter_high = counter_low >> 16;
    counter_low &= 0xFFFF;
    cnt_led++;
    if (cnt_led == TIMER_EVENT_FREQUENCY - 1)
    {
      led_state ^= LED;
      cnt_led = 0;
    }
    Process_Timer_Event();
  }
}
