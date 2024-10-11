#include <dev_ina3221.h>
#include <dev_ina226.h>
#include <ina3221.h>
#include <stdlib.h>

typedef struct {
  DEV_INA226Data data[3];
} INA3221Data;

static const INA3221Config dcfg = {
    .channel_enable = {1, 1, 1},
.base_config = {
        .vshct = INA_VSHCT_1100,
        .vbusct = INA_VBUSCT_1100,
        .awg = INA_AVG_256,
        .mode = INA_MODE_SHUNT_BUS_TRIG
    }
};

void* ina3221_initializer(int idx)
{
  DEV_INA226Config* cfg = malloc(sizeof(DEV_INA226Config));
  if (cfg)
    cfg->r = 100; //mOhm
  return cfg;
}

static void collect_channel_data(int idx, int channel, int r, DEV_INA226Data *data)
{
  int rc = ina3221GetBusVoltage(idx, INA3221_DEVICE_ID, channel, &data->voltage);
  if (rc)
    data->voltage = 0;
  rc = ina3221GetShuntCurrent(idx, INA3221_DEVICE_ID, r, channel, &data->current);
  if (rc)
    data->current = 0;
  data->current /= 100;
  data->power = abs(data->current) / 10 * abs(data->voltage) / 1000;
}

void *ina3221_data_collector(int idx, int step, void* config, void *prev_data)
{
  INA3221Data *data;
  DEV_INA226Config* cfg;

  if (step != 9)
    return prev_data;

  data = calloc(1, sizeof(INA3221Data));
  cfg = (DEV_INA226Config*)config;
  if (data)
  {
    collect_channel_data(idx, 0, cfg->r, &data->data[0]);
    if (!idx || idx == 2)
    {
      collect_channel_data(idx, 1, cfg->r, &data->data[1]);
      if (idx == 2)
        data->data[1].main_power = data->data[0].power;
    }
    if (!idx)
    {
      collect_channel_data(idx, 2, cfg->r, &data->data[2]);
      data->data[2].main_power = data->data[0].power;
      data->data[2].other_power = data->data[1].power;
    }
  }
  ina3221SetConfig(idx, INA3221_DEVICE_ID, &dcfg);
  return data;
}

void ina3221_ui_handler(int x, int y, int idx, void* data, void* config)
{
  INA3221Data* d = (INA3221Data*)data;
  ina226_ui_handler(x, y, 0, &d->data[idx], config);
}
