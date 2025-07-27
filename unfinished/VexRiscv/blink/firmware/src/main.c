#define LED_ADDRESS ((volatile unsigned int*)0x30000000)

void delay(unsigned int us);

__attribute__((naked)) int main(void)
{
  unsigned int state = 1;
  while (1)
  {
    delay(1000000);
    state ^= 1;
    *LED_ADDRESS = state;
  }
}
