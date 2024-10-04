#define LED_ADDRESS ((volatile char*)0xC0000000)

static char state = 7;

int wfi(void);

extern int interrupt;

int main(void)
{
  while (1)
  {
    wfi();
    state ^= 4;
    *LED_ADDRESS = state;
  }
}
