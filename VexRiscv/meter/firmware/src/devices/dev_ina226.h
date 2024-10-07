#ifndef _DEV_INA226_H_
#define _DEV_INA226_H_

typedef struct {
  int current, voltage;
  unsigned int power, main_power, other_power;
} DEV_INA226Data;

typedef struct {
  int r;
} DEV_INA226Config;

#define INA226_DEVICE_ID 0x80

void* ina226_initializer(int idx);
void *ina226_data_collector(int idx, int step, void* config, void *data);
void ina226_ui_handler(int x, int y, int idx, void* data, void* config);

#endif

