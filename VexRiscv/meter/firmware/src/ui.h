#ifndef _UI_H
#define _UI_H

void UI_Init(void);
void Process_Timer_Event(int data_ready, unsigned int keyboard_status);
int GetX(int idx);
int GetY(int idx);
void enableCursor(unsigned int position);
void DrawLcdChar(int x, int col, int y, char c, const FONT_INFO* f, unsigned int textColor, unsigned int bkColor, unsigned int swapColors);
void DrawLcdText(int x, int col, int y, char* text, const FONT_INFO* f, unsigned int textColor, unsigned int bkColor, unsigned int swapColors);
void LcdPrintf(const char *format, unsigned int column, unsigned int row, const FONT_INFO *f, int white_on_black, ...);

extern unsigned int cursorPosition, cursorEnabled;

#endif
