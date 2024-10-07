#ifndef _DEV_KEYBOARD_H
#define _DEV_KEYBOARD_H

#define KEYBOARD_EVENT_ENTER 0
#define KEYBOARD_EVENT_LEAVE 1
#define KEYBOARD_EVENT_KEY1  2
#define KEYBOARD_EVENT_KEY2  3
#define KEYBOARD_EVENT_KEY3  4
#define KEYBOARD_EVENT_KEY4  5
#define KEYBOARD_EVENT_KEY5  6
#define KEYBOARD_EVENT_KEY6  7
#define KEYBOARD_EVENT_KEY7  8
#define KEYBOARD_EVENT_KEY8  9

void build_keyboard_device_list(int keyboard_present);
int process_keyboard_event(unsigned int keyboard_status);
unsigned int keyboard_get_filtered_status(void);
void process_cursor_off_event(void);

#endif
