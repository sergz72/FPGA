#ifndef _DEVICES_H
#define _DEVICES_H

#define MAX_DEVICES 4

#include <shell.h>

typedef struct {
  const char *name;
  int device_id, min_devices, max_devices;
  void* (*initializer)(int idx);
  void* (*data_collector)(int idx, int step, void *config, void *data);
  void (*ui_init_handler)(int x, int y, int idx, void *config);
  void (*ui_data_handler)(int x, int y, int idx, void* data, void *config);
  void (*ui_keyboard_handler)(int x, int y, int idx, void *config, unsigned int event);
  int (*print_config)(printf_func pfunc, void *device_config, int idx);
  int (*set_config)(printf_func pfunc, int argc, char **argv, void *device_config, int idx);
  unsigned int set_config_parameter_count;
  const char *set_config_help;
  unsigned int menu_length;
  unsigned char *menu;
} Device;

extern int device_list[MAX_DEVICES];
extern void *device_data[MAX_DEVICES];
extern void* device_config[MAX_DEVICES];

void BuildDeviceList(int keyboard_idx);
void BuildShellCommands(void);
void BuildDeviceData(int step);
int I2CCheck(int idx, int device_id);
int CallUIHandler(int device_id, int x, int y, int idx, void* data, void *config);
int IsKeyboardDevice(int device_id);
void SetKeyboardMenu(int device_id, unsigned char *menu);
int CallKeyboardHandler(int device_id, int x, int y, int idx, void* config, unsigned int event);
int CallUIInitHandler(int device_id, int x, int y, int idx, void* config);

#endif

