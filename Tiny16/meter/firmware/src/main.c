#define LED_ADDRESS ((volatile int*)0xC000)

static unsigned short int state = 7;
static const unsigned short int delay = 10000;

int main(void)
{
  unsigned short int i;

  while (1)
  {  
    for (i = 0; i < delay; i++)
      __asm__ volatile("nop");
    state ^= 4;
    *LED_ADDRESS = state;
  }
}
