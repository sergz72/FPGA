#define LED_ADDRESS ((volatile int*)0xC0000000)

static int state = 7;

volatile int interrupt;

int main(void)
{
  int i;

  interrupt = 0;
  
  while (1)
  {  
//    while (!interrupt)
//      asm volatile ("nop");
    asm volatile ("wfi");
    interrupt = 0;
    state ^= 4;
    *LED_ADDRESS = state;
  }
}
