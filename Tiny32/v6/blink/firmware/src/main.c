#define LED_ADDRESS 0xC0000000

static unsigned int state = 1;

void wfi(void);
void hlt(void);
void out(unsigned int value, unsigned int address);
unsigned int in(unsigned int address);

__attribute__((naked)) int main(void)
{
  if (in(LED_ADDRESS) != 0x12345678)
    hlt();

  while (1)
  {
    wfi();
    state ^= 1;
    out(state, LED_ADDRESS);
  }
}
