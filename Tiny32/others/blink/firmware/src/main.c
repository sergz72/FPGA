#define LED_ADDRESS ((volatile int*)0xC0000000)

static int state = 1;

void wfi(void);
void hlt(void);

extern int interrupt;

__attribute__((naked)) int main(void)
{
  while (1)
  {
    wfi();
    state ^= 1;
    *LED_ADDRESS = state;
  }
}
