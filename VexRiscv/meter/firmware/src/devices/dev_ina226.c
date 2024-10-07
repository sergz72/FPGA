#include <dev_ina226.h>
#include <stddef.h>
#include <lcd_ks0108_buffered.h>
#include <lcd.h>
#include <fonts/font5.h>
#include <ina226.h>
#include <stdlib.h>

static const INA226Config dcfg = {
  .vshct = INA_VSHCT_1100,
  .vbusct = INA_VBUSCT_1100,
  .awg = INA_AVG_256,
  .mode = INA_MODE_SHUNT_BUS_TRIG
};

void* ina226_initializer(int idx)
{
  DEV_INA226Config* cfg = malloc(sizeof(DEV_INA226Config));
  if (cfg)
    cfg->r = 100; //mOhm
  return cfg;
}

void *ina226_data_collector(int idx, int step, void *config, void *prev_data)
{
  int rc;
  DEV_INA226Data *data;
  DEV_INA226Config* cfg;

  if (step != 9)
    return prev_data;

  cfg = (DEV_INA226Config*)config;
  data = malloc(sizeof(DEV_INA226Data));
  if (data)
  {
    rc = ina226GetBusVoltage(idx, INA226_DEVICE_ID, &data->voltage);
    if (rc)
      data->voltage = 0;
    rc = ina226GetShuntCurrent(idx, INA226_DEVICE_ID, cfg->r, &data->current);
    if (rc)
      data->current = 0;
    data->current /= 100;
    data->power = abs(data->current) / 10 * abs(data->voltage) / 1000;
    data->main_power = data->other_power = 0;
  }
  ina226SetConfig(idx, INA226_DEVICE_ID, &dcfg);
  return data;
}

void ina226_ui_handler(int x, int y, int idx, void* data, void* config)
{
  unsigned int eff;
  char sign;
  DEV_INA226Data* d = (DEV_INA226Data*)data;

  LcdPrintf("U:%7d", x, y,  &fiveBySevenFontInfo, 0, d->voltage);
  y += 8;
  if (d->current < 0)
  {
    sign = '-';
    d->current = -d->current;
  }
  else
    sign = ' ';
  LcdPrintf("I:%c%4d.%d", x, y, &fiveBySevenFontInfo, 0, sign, d->current / 10, d->current % 10);
  y += 8;
  LcdPrintf("P:%7u", x, y,  &fiveBySevenFontInfo, 0, d->power);
  if (d->main_power)
  {
    y += 8;
    eff = (d->power + d->other_power) * 100 / d->main_power;
    if (eff > 100)
      LcdDrawText(x, y, "Eff:  ERR", &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, NULL);
    else
      LcdPrintf("Eff: % 3u%%", x, y, &fiveBySevenFontInfo, 0, eff);
  }
}
