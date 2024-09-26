#include <stdio.h>

void main(void)
{
  for (int i = 0; i < 256; i++)
  {
     printf("\"r%d\", ", i);
     if ((i & 0x0F) == 0x0F)
       printf("\n");
  }
  for (int i = 0; i < 256; i++)
  {
     printf("0, ");
     if ((i & 0x0F) == 0x0F)
       printf("\n");
  }
}
