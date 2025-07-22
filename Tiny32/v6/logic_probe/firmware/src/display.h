#ifndef DISPLAY_H
#define DISPLAY_H

typedef struct
{
  unsigned short x, y;
  unsigned short textColor;
  unsigned short bkColor;
  unsigned int c;
} Character;

typedef struct
{
  unsigned short x, y;
  unsigned short width, height;
  unsigned short color;
} Rectangle;

#ifdef __cplusplus
extern "C" {
#endif

void DisplayInit(void);
void DisplayInitChar(unsigned int column, unsigned int row, Character *ch);
void DisplaySetChar(unsigned int column, unsigned int row, unsigned int ch);
void DisplaySetRectangleColor(unsigned int idx, unsigned short color);
void DisplayInitRectangle(unsigned int idx, Rectangle *rc);

void DrawChar(unsigned int x, unsigned int y, unsigned int ch, unsigned int text_color, unsigned int bk_color);

#ifdef __cplusplus
}
#endif

#endif
