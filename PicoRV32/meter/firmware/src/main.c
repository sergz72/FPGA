#define LED_ADDRESS ((volatile int*)0xC0000000)

static int state = 7;
static const int delay = 10000;

int main(void)
{
  int i;

  while (1)
  {  
    for (i = 0; i < delay; i++)
      __asm__ volatile("nop");
    state ^= 4;
    *LED_ADDRESS = state;
  }
}
