#include "board.h"
#include "ui.h"

#define ROWS 2
#define CURSOR_TIMEOUT 50

unsigned int cursorPosition, cursorEnabled;

//todo
void UI_Init(void)
{
  cursorEnabled = 0;
}

int GetX(int idx)
{
  return (idx % ROWS) * LCD_WIDTH / ROWS;
}

int GetY(int idx)
{
  return (idx / ROWS) * LCD_HEIGHT / ROWS;
}

//todo
void Process_Timer_Event(int data_ready, unsigned int keyboard_status)
{
}

void enableCursor(unsigned int position)
{
  cursorPosition = position;
  cursorEnabled = CURSOR_TIMEOUT;
}

void DrawLcdChar(int x, int col, int y, char c, const FONT_INFO* f, unsigned int textColor, unsigned int bkColor, unsigned int swapColors)
{
  char text[2];
  text[0] = c;
  text[1] = 0;
  if (swapColors)
    LcdDrawText(x + col * (f->character_max_width + f->character_spacing), y, text, f, bkColor, textColor, NULL);
  else
    LcdDrawText(x + col * (f->character_max_width + f->character_spacing), y, text, f, textColor, bkColor, NULL);
}

void DrawLcdText(int x, int col, int y, char* text, const FONT_INFO* f, unsigned int textColor, unsigned int bkColor, unsigned int swapColors)
{
  if (swapColors)
    LcdDrawText(x + col * (f->character_max_width + f->character_spacing), y, text, f, bkColor, textColor, NULL);
  else
    LcdDrawText(x + col * (f->character_max_width + f->character_spacing), y, text, f, textColor, bkColor, NULL);
}

//todo
void LcdPrintf(const char *format, unsigned int column, unsigned int row, const FONT_INFO *f, int white_on_black, ...)
{
}

