#ifndef _METER_DEV_ADS1115_H
#define _METER_DEV_ADS1115_H

#define ADS1115_DEVICE_ID 0x90

void* ads1115_initializer(int idx);
void *ads1115_data_collector(int idx, int step, void* config, void *data);
void ads1115_ui_handler(int x, int y, int idx, void* data, void* config);

#endif
