#define LED_ADDRESS ((volatile int*)0xC0000000)

static int state = 7;

void wfi(void);
void hlt(void);

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
