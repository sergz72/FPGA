#include "devices.h"
#include <stddef.h>
#include <memory.h>
#include <malloc.h>
#include <stdio.h>
#include "device_list.h"

typedef struct {
  int (*print_config)(printf_func pfunc, void *device_config, int idx);
  int idx;
} get_config_command_data;

typedef struct {
  int (*set_config)(printf_func pfunc, int argc, char **argv, void *device_config, int idx);
  int idx;
} set_config_command_data;

int device_list[MAX_DEVICES];
void *device_data[MAX_DEVICES];
void* device_config[MAX_DEVICES];

static int FindDeviceId(int idx)
{
  int i;
  const Device* d;

  d = devices;
  for (i = 0; i < MAX_KNOWN_DEVICES; i++)
  {
    if (I2CCheck(idx, d->device_id))
    {
      device_config[idx] = d->initializer(idx);
      return d->device_id;
    }
    d++;
  }
  return 0;
}

void BuildDeviceList(int keyboard_idx)
{
  int i, j, id;
  const Device* d;

  for (i = 0; i < MAX_DEVICES; i++)
  {
    if (i == keyboard_idx)
    {
      device_list[i] = 0;
      continue;
    }
    id = FindDeviceId(i);
    device_list[i] = id;
    if (id)
    {
      d = devices;
      for (j = 0; j < MAX_KNOWN_DEVICES; j++)
      {
        if (d->device_id == id && d->max_devices > 1)
        {
          j = d->max_devices;
          switch (i)
          {
          case 0:
            while (--j)
              device_list[++i] = id;
            break;
          case 2:
            device_list[++i] = id;
            break;
          }
          break;
        }
        d++;
      }
    }
  }
}

void BuildDeviceData(int step)
{
  int i, j, id;
  const Device* d;

  for (i = 0; i < MAX_DEVICES; i++)
  {
    id = device_list[i];
    if (id)
    {
      d = devices;
      for (j = 0; j < MAX_KNOWN_DEVICES; j++)
      {
        if (d->device_id == id)
        {
          if (d->data_collector)
            device_data[i] = d->data_collector(i, step, device_config[i], device_data[i]);
          else
            device_data[i] = NULL;
          switch (i)
          {
          case 0:
            i += d->max_devices - 1;
            break;
          case 2:
            if (d->max_devices > 1)
              i++;
            break;
          }
        }
        d++;
      }
    }
    else
      device_data[i] = NULL;
  }
}

int CallUIInitHandler(int device_id, int x, int y, int idx, void* config)
{
  int i;

  for (i = 0; i < MAX_KNOWN_DEVICES; i++)
  {
    if (devices[i].device_id == device_id)
    {
      if (devices[i].ui_init_handler)
        devices[i].ui_init_handler(x, y, idx, config);
      return devices[i].max_devices - 1 - idx;
    }
  }
  return 0;
}

int CallUIHandler(int device_id, int x, int y, int idx, void* data, void* config)
{
  int i;

  for (i = 0; i < MAX_KNOWN_DEVICES; i++)
  {
    if (devices[i].device_id == device_id)
    {
      if (devices[i].ui_data_handler)
        devices[i].ui_data_handler(x, y, idx, data, config);
      return devices[i].max_devices - 1 - idx;
    }
  }
  return 0;
}

int CallKeyboardHandler(int device_id, int x, int y, int idx, void* config, unsigned int event)
{
  int i;

  for (i = 0; i < MAX_KNOWN_DEVICES; i++)
  {
    if (devices[i].device_id == device_id)
    {
      devices[i].ui_keyboard_handler(x, y, idx, config, event);
      return devices[i].max_devices - 1;
    }
  }
  return 0;
}

int IsKeyboardDevice(int device_id)
{
  int i;

  for (i = 0; i < MAX_KNOWN_DEVICES; i++)
  {
    if (devices[i].device_id == device_id)
      return devices[i].ui_keyboard_handler ? devices[i].max_devices : 0;
  }
  return 0;
}

void SetKeyboardMenu(int device_id, unsigned char *menu)
{
  int i;

  for (i = 0; i < MAX_KNOWN_DEVICES; i++)
  {
    if (devices[i].device_id == device_id)
    {
      menu[0] = 'r';
      memcpy(&menu[1], devices[i].menu, devices[i].menu_length);
      break;
    }
  }
}

static int get_config_handler(printf_func pfunc, gets_func gfunc, int argc, char **argv, void *data)
{
  get_config_command_data *d = (get_config_command_data *)data;
  if (d)
    return d->print_config(pfunc, device_config[d->idx], d->idx);
  return 1;
}

static int set_config_handler(printf_func pfunc, gets_func gfunc, int argc, char **argv, void *data)
{
  set_config_command_data *d = (set_config_command_data *)data;
  if (d)
    return d->set_config(pfunc, argc, argv, device_config[d->idx], d->idx);
  return 1;
}

static const ShellCommandItem *BuildCommandItems(int idx, unsigned int num_parameters,
                                                 int (*final_handler)(printf_func pfunc, gets_func gfunc, int argc, char **argv, void *data))
{
  ShellCommandItem *items = malloc(sizeof(ShellCommandItem) * (1 + num_parameters));
  ShellCommandItem *result = items;
  if (items)
  {
    while (num_parameters > 0)
    {
      items->text = NULL;
      items->final_handler = NULL;
      items->handler = param_handler;
      items++;
      num_parameters--;
    }
    items->text = NULL;
    items->handler = NULL;
    items->final_handler = final_handler;
  }
  return result;
}

static void BuildPrintConfigCommand(const Device* d, int idx)
{
  if (!d->print_config)
    return;
  get_config_command_data *data;
  ShellCommand *cmd = malloc(sizeof(ShellCommand));
  if (cmd)
  {
    cmd->name = malloc(strlen(d->name) + 6);
    if (cmd->name)
    {
      data = malloc(sizeof(get_config_command_data));
      if (data)
      {
        //todo
        //sprintf((char*)cmd->name, "%s%d_get", d->name, idx);
        cmd->help = NULL;
        cmd->init = NULL;
        data->idx = idx;
        data->print_config = d->print_config;
        cmd->data = data;
        cmd->items = BuildCommandItems(idx, 0, get_config_handler);
        shell_register_command(cmd);
      }
    }
  }
}

static void BuildSetConfigCommand(const Device* d, int idx)
{
  if (!d->set_config)
    return;
  set_config_command_data *data;
  ShellCommand *cmd = malloc(sizeof(ShellCommand));
  if (cmd)
  {
    cmd->name = malloc(strlen(d->name) + 6);
    cmd->help = malloc(strlen(d->name) + 7 + strlen(d->set_config_help));
    if (cmd->name && cmd->help)
    {
      data = malloc(sizeof(set_config_command_data));
      if (data)
      {
        //todo
        //sprintf((char*)cmd->name, "%s%d_set", d->name, idx);
        //sprintf((char*)cmd->help, "%s %s", cmd->name, d->set_config_help);
        cmd->help = NULL;
        cmd->init = NULL;
        data->idx = idx;
        data->set_config = d->set_config;
        cmd->data = data;
        cmd->items = BuildCommandItems(idx, d->set_config_parameter_count, set_config_handler);
        shell_register_command(cmd);
      }
    }
  }
}

void BuildShellCommands(void)
{
  int i, j, id;
  const Device* d;

  for (i = 0; i < MAX_DEVICES; i++)
  {
    id = device_list[i];
    if (id)
    {
      d = devices;
      for (j = 0; j < MAX_KNOWN_DEVICES; j++)
      {
        if (d->device_id == id)
        {
          BuildPrintConfigCommand(d, i);
          BuildSetConfigCommand(d, i);
        }
        d++;
      }
    }
  }
}
