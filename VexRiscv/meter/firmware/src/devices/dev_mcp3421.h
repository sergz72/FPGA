#ifndef _DEV_MCP3421_H_
#define _DEV_MCP3421_H_

#include <shell.h>

#define MCP3421_DEVICE_ID 0xD0

void* mcp3421_initializer(int idx);
void *mcp3421_data_collector(int idx, int step, void* config, void *data);
void mcp3421_ui_handler(int x, int y, int idx, void* data, void* config);
int msp3421_print_config(printf_func pfunc, void *device_config, int idx);
int msp3421_set_config(printf_func pfunc, int argc, char **argv, void *device_config, int idx);

#endif

