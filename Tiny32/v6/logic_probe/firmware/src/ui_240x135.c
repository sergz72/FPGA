#include "board.h"
#include <ui.h>
#include <lcd_st7789.h>
#include <display.h>
#include "font16.h"
#include "stdlib.h"

#define HIGH_COLOR RGB(128, 255, 128)
#define Z_COLOR RGB(255, 255, 128)
#define LOW_COLOR RGB(255, 128, 128)

#define FONT courierNew16ptFontInfo

#define FREQUENCY_COLUMNS 8

const unsigned int frequency_columns[FREQUENCY_COLUMNS] = { 2, 3, 4, 6, 7, 8, 10, 11 };

static int counter;

static void init_row(unsigned int row, unsigned short color)
{
  Character c;

  c.x = 0;
  c.y = row * FONT_HEIGHT;
  c.textColor = color;
  c.bkColor = BLACK_COLOR;
  for (unsigned int i = 0; i < DISPLAY_MAX_COLUMNS; i++)
  {
    DisplayInitChar(i, row, &c);
    c.x += 16;
  }
  DisplaySetChar(0, row, CHAR_F);
  DisplaySetChar(5, row, CHAR_PUNKT);
  DisplaySetChar(9, row, CHAR_PUNKT);
  DisplaySetChar(12, row, 0);
}

static void initU(unsigned int column, char t, unsigned short color)
{
  Character c;

  c.x = column * 16;
  c.y = FONT_HEIGHT * 3;
  c.textColor = color;
  c.bkColor = BLACK_COLOR;
  DisplayInitChar(column, 3, &c);
  DisplaySetChar(column, 3, CHAR_U);
  c.x += 16;
  column++;
  DisplayInitChar(column, 3, &c);
  DisplaySetChar(column, 3, t);
  c.x += 32;
  column += 2;
  DisplayInitChar(column, 3, &c);
  c.x += 16;
  column++;
  DisplayInitChar(column, 3, &c);
  DisplaySetChar(column, 3, CHAR_PUNKT);
  c.x += 16;
  column++;
  DisplayInitChar(column, 3, &c);
}

static void init_row3(void)
{
  initU(0, CHAR_H, HIGH_COLOR);
  initU(7, CHAR_L, LOW_COLOR);
}

static void initP(unsigned int column, unsigned int row, char t, unsigned short color)
{
  Character c;

  c.x = column * 16;
  c.y = FONT_HEIGHT * row;
  c.textColor = color;
  c.bkColor = BLACK_COLOR;
  DisplayInitChar(column, row, &c);
  DisplaySetChar(column, row, t);
  c.x += 16;
  column++;
  DisplayInitChar(column, row, &c);
  c.x += 16;
  column++;
  DisplayInitChar(column, row, &c);
  c.x += 16;
  column++;
  DisplayInitChar(column, row, &c);
  c.x += 16;
  column++;
  DisplayInitChar(column, row, &c);
  DisplaySetChar(column, row, CHAR_PERCENT);
}

static void init_row4(void)
{
  initP(0, 4, CHAR_H, HIGH_COLOR);
  initP(5, 4, CHAR_Z, Z_COLOR);
}

static void init_row5(void)
{
  initP(0, 5, CHAR_L, LOW_COLOR);
}

void UI_Init(void)
{
  Rectangle r;

  counter = 0;

  UI_CommonInit();

  LcdInit(ST7789_MADCTL_VALUE);
  DisplayInit();
  init_row(0, HIGH_COLOR);
  init_row(1, Z_COLOR);
  init_row(2, LOW_COLOR);
  DisplaySetChar(1, 0, CHAR_H);
  DisplaySetChar(1, 2, CHAR_L);
  init_row3();
  init_row4();
  init_row5();

  r.x = 16 * 13;
  r.y = 0;
  r.width = 32;
  r.height = 33;
  DisplayInitRectangle(0, &r);
  r.y += 34;
  DisplayInitRectangle(1, &r);
  r.y += 34;
  DisplayInitRectangle(2, &r);
  r.y += 34;
  DisplayInitRectangle(3, &r);
}

static void ShowFrequency(unsigned int row, unsigned int frequency)
{
  div_t d;

  d.quot = (int)frequency;
  for (int i = FREQUENCY_COLUMNS - 1; i >= 0; i--)
  {
    if (i < 2 && !d.quot)
      d.rem = CHAR_SPACE;
    else
      d = div(d.quot, 10);
    DisplaySetChar(frequency_columns[i], row, d.rem);
  }
}

static void ShowDuty(unsigned int column, unsigned int row, unsigned int duty)
{
  div_t d = div((int)duty, 10);
  DisplaySetChar(column+2, row, d.rem);
  if (duty >= 10)
  {
    div_t d2 = div(d.quot, 10);
    DisplaySetChar(column+1, row, d2.rem);
    if (duty >= 100)
      DisplaySetChar(column, row, d2.quot);
    else
      DisplaySetChar(column, row, CHAR_SPACE);
  }
  else
  {
    DisplaySetChar(column+1, row, CHAR_SPACE);
    DisplaySetChar(column, row, CHAR_SPACE);
  }
}

static void ShowVoltage(unsigned int column, unsigned int value)
{
  div_t d = div((int)value, 10);
  DisplaySetChar(column, 3, d.quot);
  DisplaySetChar(column + 2, 3, d.rem);
}

static void ShowLedData(void)
{
  // counter_low * 255 / COUNTERS_MAX
  unsigned int value = ((counter_low << 8) - counter_low) / COUNTERS_MAX;
  DisplaySetRectangleColor(0, RGB(value, 0, 0));
  value = ((counter_z << 8) - counter_z) / COUNTERS_MAX;
  DisplaySetRectangleColor(1, RGB(value, value, 0));
  value = ((counter_high << 8) - counter_high) / COUNTERS_MAX;
  DisplaySetRectangleColor(2, RGB(0, value, 0));
  int pulse = (counter_freq_rs != 0) || ((counter_freq_high != 0) && (counter_freq_low != 0));
  DisplaySetRectangleColor(3, pulse ? BLUE_COLOR : BLACK_COLOR);
}

void Process_Timer_Event(void)
{
  ShowLedData();

  Process_Button_Events();

  counter++;
  if (counter == 5)
  {
    counter = 0;
    ShowFrequency(0, counter_freq_high);
    ShowFrequency(1, counter_freq_rs);
    ShowFrequency(2, counter_freq_low);
    ShowDuty(1, 4, counter_high * 100 / COUNTERS_MAX);
    ShowDuty(6, 4, counter_z * 100 / COUNTERS_MAX);
    ShowDuty(1, 5, counter_low * 100 / COUNTERS_MAX);
    if (uh_changed_to)
    {
      ShowVoltage(3, uh_changed_to);
      uh_changed_to = 0;
    }
    if (ul_changed_to)
    {
      ShowVoltage(10, ul_changed_to);
      ul_changed_to = 0;
    }
  }
}
