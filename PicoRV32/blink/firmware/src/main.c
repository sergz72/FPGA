#define LED_ADDRESS ((volatile int*)0x30000000)

static int state = 1;

int wfi(void);
int getq(void);
int timer(int value);

__attribute__((naked)) int main(void)
{
  int counter = 0;
  while (1)
  {
    timer(270000);
    wfi();
    if (counter == 99)
    {
      counter = 0;
      state ^= 1;
      *LED_ADDRESS = state;
    }
    else
      counter++;
  }
}
