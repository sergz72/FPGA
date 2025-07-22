#include "font16.h"
#include <lcd_st7789.h>

static void draw_symbol_30(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_31(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_32(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_33(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_34(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_35(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_36(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_37(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_38(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_39(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_25(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_46(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_48(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_4c(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_55(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_5a(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_2e(unsigned int text_color, unsigned int bk_color);
static void draw_symbol_20(unsigned int text_color, unsigned int bk_color);

const draw_symbol font16_symbols[18] = {
  draw_symbol_30,
  draw_symbol_31,
  draw_symbol_32,
  draw_symbol_33,
  draw_symbol_34,
  draw_symbol_35,
  draw_symbol_36,
  draw_symbol_37,
  draw_symbol_38,
  draw_symbol_39,
  draw_symbol_25,
  draw_symbol_46,
  draw_symbol_48,
  draw_symbol_4c,
  draw_symbol_55,
  draw_symbol_5a,
  draw_symbol_2e,
  draw_symbol_20,
};

//0
static void draw_symbol_30(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 21);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 103);
}

//1
static void draw_symbol_31(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 21);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 1);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 9);
  ST7789_WriteColor(bk_color, 101);
}

//2
static void draw_symbol_32(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 20);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 8);
  ST7789_WriteColor(bk_color, 102);
}

//3
static void draw_symbol_33(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 20);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 16);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 16);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 16);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 6);
  ST7789_WriteColor(bk_color, 103);
}

//4
static void draw_symbol_34(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 23);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 1);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 2);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 2);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 8);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 102);
}

//5
static void draw_symbol_35(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 19);
  ST7789_WriteColor(text_color, 6);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 1);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 16);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 104);
}

//6
static void draw_symbol_36(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 23);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 2);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 1);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 103);
}

//7
static void draw_symbol_37(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 18);
  ST7789_WriteColor(text_color, 8);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 105);
}

//8
static void draw_symbol_38(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 20);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 104);
}

//9
static void draw_symbol_39(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 21);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 1);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 104);
}

//%
static void draw_symbol_25(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 19);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 18);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 4);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 2);
  ST7789_WriteColor(bk_color, 18);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 12);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 103);
}

//F
static void draw_symbol_46(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 33);
  ST7789_WriteColor(text_color, 10);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 11);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 7);
  ST7789_WriteColor(bk_color, 104);
}

//H
static void draw_symbol_48(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 32);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 9);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 99);
}

//L
static void draw_symbol_4c(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 34);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 10);
  ST7789_WriteColor(bk_color, 100);
}

//U
static void draw_symbol_55(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 32);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 3);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 10);
  ST7789_WriteColor(text_color, 5);
  ST7789_WriteColor(bk_color, 103);
}

//Z
static void draw_symbol_5a(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 34);
  ST7789_WriteColor(text_color, 9);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 15);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 14);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 4);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 9);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 5);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 8);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 6);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 1);
  ST7789_WriteColor(bk_color, 7);
  ST7789_WriteColor(text_color, 9);
  ST7789_WriteColor(bk_color, 101);
}

//.
static void draw_symbol_2e(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 180);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 13);
  ST7789_WriteColor(text_color, 3);
  ST7789_WriteColor(bk_color, 105);
}

// 
static void draw_symbol_20(unsigned int text_color, unsigned int bk_color)
{
  ST7789_WriteColor(bk_color, 320);
}

