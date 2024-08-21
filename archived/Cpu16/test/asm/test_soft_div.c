#include <stdio.h>

//Step-1: First the registers are initialized with corresponding values (Q = Dividend, M = Divisor, A = 0, n = number of bits in dividend)
//Step-2: Then the content of register A and Q is shifted left as if they are a single unit
//Step-3: Then content of register M is subtracted from A and result is stored in A
//Step-4: Then the most significant bit of the A is checked if it is 0 the least significant bit of Q is set to 1 otherwise if it is 1 the least significant bit of Q is set to 0
//and value of register A is restored i.e the value of A before the subtraction with M
//Step-5: The value of counter n is decremented
//Step-6: If the value of n becomes zero we get of the loop otherwise we repeat from step 2
//Step-7: Finally, the register Q contain the quotient and A contain remainder

int main(int argc, char** argv)
{
  unsigned short dividh = 0;
  unsigned short dividl = 10005;
  unsigned short divis = 10;
  unsigned short a = 0;
  unsigned short counter = 32;
  unsigned short temp, temp2;

  printf("dividh=%d dividl=%d divis=%d\n", dividh, dividl, divis);

  while (counter--)
  {
    temp = dividl;
    temp2 = dividh;
    dividl <<= 1;
    dividh <<= 1;
    if (temp & 0x8000)
      dividh |= 1;
    a <<= 1;
    if (temp2 & 0x8000)
      a |= 1;
    temp = a - divis;
    if (!(temp & 0x8000))
    {
      dividl |= 1;
      a = temp;
    }
    printf("counter=%d dividh=%d dividl=%d a=%d temp=%x\n", counter, dividh, dividl, a, temp);
  }

  return 0;
}
