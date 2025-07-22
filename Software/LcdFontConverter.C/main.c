#include <stdio.h>
#include <font8_2.h>
#include <font16.h>
#include <string.h>

#define COLOR_NONE       0
#define COLOR_TEXT       1
#define COLOR_BACKGROUND 2

static int build_c16_font(const char *symbols)
{
  int length = strlen(symbols);
  printf("#include \"font16.h\"\n#include <lcd_st7789.h>\n\n");
  for (int ch = 0; ch < length; ch++)
    printf("void draw_symbol_%02x(unsigned int text_color, unsigned int bk_color);\n", symbols[ch]);
  printf("\ntypedef (*draw_symbol)(unsigned int text_color, unsigned int bk_color);\n\n");
  printf("const draw_symbol[%d] font16_symbols = [\n", length);
  unsigned char c = (unsigned char)courierNew16ptFontInfo.start_character;
  for (int ch = 0; ch < length; ch++)
    printf("  draw_symbol_%02x,\n", symbols[ch]);
  printf("];\n\n");
  for (int ch = 0; ch < length; ch++)
  {
    unsigned int c = symbols[ch];
    const unsigned char *p = courierNew16ptFontInfo.char_bitmaps +
                            (c - courierNew16ptFontInfo.start_character) * courierNew16ptFontInfo.char_height;
    printf("//%c\n", c);
    printf("static void draw_symbol_%02x(unsigned int text_color, unsigned int bk_color)\n{\n", c);
    unsigned int char_bytes = courierNew16ptFontInfo.char_height << 1;
    unsigned int prev_color = COLOR_NONE;
    unsigned int pixel_counter = 0;
    for (int y = 0; y < char_bytes; y++)
    {
      unsigned char b = *p++;
      for (int i = 0; i < 8; i++)
      {
        unsigned int color = b & 0x80 ? COLOR_TEXT : COLOR_BACKGROUND;
        if (color == prev_color)
          pixel_counter++;
        else
        {
          if (prev_color != COLOR_NONE)
            printf("  ST7789_WriteColor(%s, %d);\n", prev_color == COLOR_TEXT ? "text_color" : "bk_color", pixel_counter);
          prev_color = color;
          pixel_counter = 1;
        }
        b <<= 1;
      }
    }
    printf("  ST7789_WriteColor(%s, %d);\n", prev_color == COLOR_TEXT ? "text_color" : "bk_color", pixel_counter);
    printf("}\n\n");
  }

  return 0;
}

int main(int argc, char **argv)
{
  if (argc == 3 && !strcmp(argv[1], "c16"))
    return build_c16_font(argv[2]);

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
