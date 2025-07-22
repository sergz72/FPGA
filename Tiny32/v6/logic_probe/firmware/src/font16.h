#ifndef FONT16_H
#define FONT16_H

#define FONT_WIDTH           16
#define FONT_HEIGHT          20
#define FONT_START_CHARACTER 0x20

//"0123456789%FHLUZ. "
#define CHAR_PERCENT 10
#define CHAR_F       11
#define CHAR_H       12
#define CHAR_L       13
#define CHAR_U       14
#define CHAR_Z       15
#define CHAR_PUNKT   16
#define CHAR_SPACE   17

typedef void (*draw_symbol)(unsigned int text_color, unsigned int bk_color);

extern const draw_symbol font16_symbols[18];

#endif

