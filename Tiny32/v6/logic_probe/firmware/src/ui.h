#ifndef UI_H
#define UI_H

void UI_Init(void);
void Process_Timer_Event(void);
void UI_CommonInit(void);
void DrawMode(void);
void Process_Button_Events(void);
void calculate_led_data(void);

extern unsigned int led_data[4];
extern unsigned int uh_changed_to, ul_changed_to;

#endif
