#include "board.h"
#include <display.h>
#include <lcd_st7789.h>
#include <string.h>
#include "font16.h"

typedef struct
{
  Character chars[DISPLAY_MAX_ROWS][DISPLAY_MAX_COLUMNS];
  Rectangle rectangles[DISPLAY_MAX_RECTANGLES];
} Display;

static Display display;

void DisplayInit(void)
{
  memset(&display, 0, sizeof(display));
  for (int y = 0; y < DISPLAY_MAX_ROWS; y++)
    for (int x = 0; x < DISPLAY_MAX_COLUMNS; x++)
      display.chars[y][x].c = CHAR_SPACE;
}

void DisplayInitChar(unsigned int column, unsigned int row, Character *ch)
{
  Character *c = &display.chars[row][column];
  c->x = ch->x;
  c->y = ch->y;
  c->bkColor = ch->bkColor;
  c->textColor = ch->textColor;
  c->c = CHAR_SPACE;
}

void DisplayInitRectangle(unsigned int idx, Rectangle *rc)
{
  Rectangle *r = &display.rectangles[idx];
  r->x = rc->x;
  r->y = rc->y;
  r->width = rc->width;
  r->height = rc->height;
  r->color = BLACK_COLOR;
}

void DisplaySetRectangleColor(unsigned int idx, unsigned short color)
{
  Rectangle *r = &display.rectangles[idx];
  if (r->color == color)
    return;
  r->color = color;
  LcdRectFill(r->x, r->y, r->width, r->height, color);
}

void DisplaySetChar(unsigned int column, unsigned int row, unsigned int ch)
{
  Character *c = &display.chars[row][column];
  if (c->c != ch)
  {
    c->c = ch;
    DrawChar(c->x, c->y, ch, c->textColor, c->bkColor);
  }
}
