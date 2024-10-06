#define LED_ADDRESS ((volatile char*)0xC0000000)

static char state = 7;

int main(void)
{
  int i;

  while (1)
  {  
    asm volatile ("wfi");
    state ^= 4;
    *LED_ADDRESS = state;
  }
}
