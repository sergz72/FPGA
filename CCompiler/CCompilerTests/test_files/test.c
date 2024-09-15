const unsigned short *KS0108 = 0x2000;

void isr(void)
{
}

void main(void)
{
  unsigned short i = 0;

  i += 9;

  *KS0108 = i;
}
