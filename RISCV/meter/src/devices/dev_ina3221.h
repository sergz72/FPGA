#ifndef _DEV_INA3221_H_
#define _DEV_INA3221_H_

#define INA3221_DEVICE_ID 0x82

void* ina3221_initializer(int idx);
void *ina3221_data_collector(int idx, int step, void* config, void *data);
void ina3221_ui_handler(int x, int y, int idx, void* data, void* config);

#endif

