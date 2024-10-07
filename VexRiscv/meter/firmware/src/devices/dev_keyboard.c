#include "dev_keyboard.h"
#include <devices.h>
#include "board.h"
#include <memory.h>
#include "ui.h"

static unsigned int max_keyboard_devices, keyboard_devices[MAX_DEVICES], current_keyboard_status;
static int current_keyboard_device;

//todo
static void show_menu(void)
{
}

void build_keyboard_device_list(int keyboard_present)
{
  int i, id, max_devices;

  current_keyboard_device = -1;
  max_keyboard_devices = 0;
  current_keyboard_status = 0;

  if (!keyboard_present)
    return;

  for (i = 0; i < MAX_DEVICES; i++)
  {
    id = device_list[i];
    if (id)
    {
      max_devices = IsKeyboardDevice(id);
      if (max_devices)
      {
        keyboard_devices[max_keyboard_devices] = i;
        max_keyboard_devices++;
        i += max_devices - 1;
      }
    }
  }
  if (max_keyboard_devices)
    show_menu();
}

static void send_keyboard_event(unsigned int event)
{
  int idx = (int)keyboard_devices[current_keyboard_device];
  int id = device_list[idx];
  CallKeyboardHandler(id, GetX(idx), GetY(idx), idx, device_config[idx], event);
}

unsigned int convert_keyboard_status(unsigned int keyboard_status)
{
  unsigned int v = 1, key = KEYBOARD_EVENT_KEY1;
  int i;

  for (i = 0; i < 8; i++)
  {
    if (keyboard_status & v)
      return key;
    v <<= 1;
    key++;
  }

  return 0;
}

void process_cursor_off_event(void)
{
  if (current_keyboard_device >= 0)
    send_keyboard_event(KEYBOARD_EVENT_LEAVE);
}

int process_keyboard_event(unsigned int keyboard_status)
{
  keyboard_status = convert_keyboard_status(keyboard_status);
  if (max_keyboard_devices)
  {
    if (current_keyboard_device >= 0)
    {
      if (keyboard_status == KEYBOARD_EVENT_KEY1)
      {
        cursorEnabled = 0;
        send_keyboard_event(KEYBOARD_EVENT_LEAVE);
        current_keyboard_device = -1;
        show_menu();
      }
      else
        send_keyboard_event(keyboard_status);
      return 1;
    }
    else
    {
      if (keyboard_status >= KEYBOARD_EVENT_KEY1 && keyboard_status < max_keyboard_devices + KEYBOARD_EVENT_KEY1)
      {
        current_keyboard_device = keyboard_status - KEYBOARD_EVENT_KEY1;
        show_menu();
        send_keyboard_event(KEYBOARD_EVENT_ENTER);
        return 1;
      }
    }
  }
  return 0;
}

unsigned int keyboard_get_filtered_status(void)
{
  unsigned int status = keyboard_get_status();
  if (status != current_keyboard_status)
  {
    current_keyboard_status = status;
    return status;
  }
  return 0;
}
