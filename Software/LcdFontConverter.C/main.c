#include <stdio.h>
#include <font8_2.h>
#include <string.h>

int main(int argc, char **argv)
{
  int c_language = argc == 2 && !strcmp(argv[1], "c");

  char c = courierNew8ptFontInfo.start_character;
  const unsigned char *p = courierNew8ptFontInfo.char_bitmaps;
  for (int ch = 0; ch < courierNew8ptFontInfo.character_count; ch++)
  {
    int mask = 0x80;
    if (c_language)
      printf("  //%c\n  {", c);
    else
      printf("\t;%c\n", c);
    for (int x = 0; x < 8; x++)
    {
      const unsigned char *chp = p;
      unsigned char data = 0;
      for (int y = 0; y < 8; y++)
      {
        data >>= 1;
        if (*chp & mask)
          data |= 0x80;
        chp++;
      }
      if (c_language)
      {
        if (x < 7)
          printf("0x%X,", data);
        else
          printf("0x%X},\n", data);
      }
      else
        printf("\tdw $%X\n", data);
      mask >>= 1;
    }
    p += courierNew8ptFontInfo.char_height;
    c++;
  }
  return 0;
}
