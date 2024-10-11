#include <malloc.h>
#include "dev_ads1115.h"
#include <lcd.h>
#include <fonts/font5.h>
#include <lcd_ks0108_buffered.h>
#include <ads1115.h>

typedef struct {
  int voltage[4];
} DEV_ADS1115Data;

typedef struct {
  int divider[4];
} DEV_ADS1115Config;

static const ADS1115Config dcfg[4] = {
    {
        .dr = ADS1115_DR_8,
        .mux = ADS1115_MUX_AIN0_GND,
        .pga = ADS1115_PGA_4096,
        .comp_que = ADS1115_COMP_QUE_DISABLE,
        .os = 1,
        .single_shot_mode = 1,
        .comp_active_high = 0,
        .comp_mode_window = 0,
        .comp_latching = 0,
    },
    {
        .dr = ADS1115_DR_8,
        .mux = ADS1115_MUX_AIN1_GND,
        .pga = ADS1115_PGA_4096,
        .comp_que = ADS1115_COMP_QUE_DISABLE,
        .os = 1,
        .single_shot_mode = 1,
        .comp_active_high = 0,
        .comp_mode_window = 0,
        .comp_latching = 0,
    },
    {
        .dr = ADS1115_DR_8,
        .mux = ADS1115_MUX_AIN2_GND,
        .pga = ADS1115_PGA_4096,
        .comp_que = ADS1115_COMP_QUE_DISABLE,
        .os = 1,
        .single_shot_mode = 1,
        .comp_active_high = 0,
        .comp_mode_window = 0,
        .comp_latching = 0,
    },
    {
        .dr = ADS1115_DR_8,
        .mux = ADS1115_MUX_AIN3_GND,
        .pga = ADS1115_PGA_4096,
        .comp_que = ADS1115_COMP_QUE_DISABLE,
        .os = 1,
        .single_shot_mode = 1,
        .comp_active_high = 0,
        .comp_mode_window = 0,
        .comp_latching = 0,
    }
};

void* ads1115_initializer(int idx)
{
  DEV_ADS1115Config* cfg = malloc(sizeof(DEV_ADS1115Config));
  if (cfg)
    cfg->divider[0] = cfg->divider[1] = cfg->divider[2] = cfg->divider[3] = 10;
  return cfg;
}

static void getResult(int idx, int channel, int divider, void *d)
{
  DEV_ADS1115Data *data;
  int rc;

  if (d)
  {
    data = (DEV_ADS1115Data *)d;
    rc = ads1115GetVoltage(idx, ADS1115_DEVICE_ID, dcfg[channel].pga, &data->voltage[channel]);
    if (rc)
      data->voltage[channel] = 0;
    else
    {
      data->voltage[channel] /= 1000 / divider;
    }
  }
}

void *ads1115_data_collector(int idx, int step, void* config, void *prev_data)
{
  DEV_ADS1115Config* cfg = (DEV_ADS1115Config*)config;

  switch (step)
  {
    case 1:
      prev_data = malloc(sizeof(DEV_ADS1115Data));
      ads1115SetConfig(idx, ADS1115_DEVICE_ID, &dcfg[0]);
      break;
    case 3:
      getResult(idx, 0, cfg->divider[0], prev_data);
      ads1115SetConfig(idx, ADS1115_DEVICE_ID, &dcfg[1]);
      break;
    case 5:
      getResult(idx, 1, cfg->divider[1], prev_data);
      ads1115SetConfig(idx, ADS1115_DEVICE_ID, &dcfg[2]);
      break;
    case 7:
      getResult(idx, 2, cfg->divider[2], prev_data);
      ads1115SetConfig(idx, ADS1115_DEVICE_ID, &dcfg[3]);
      break;
    case 9:
      getResult(idx, 3, cfg->divider[3], prev_data);
      break;
  }
  return prev_data;
}

void ads1115_ui_handler(int x, int y, int idx, void* data, void* config)
{
  int i, v;
  char sign;
  DEV_ADS1115Data* d = (DEV_ADS1115Data*)data;

  for (i = 0; i < 4; i++)
  {
    v = d->voltage[i];
    if (v < 0)
    {
      sign = '-';
      v = -v;
    }
    else
      sign = ' ';
    LcdPrintf("U%d%c%2d.%03d", x, y, &fiveBySevenFontInfo, 0, i, sign, v / 1000, v % 1000);
    y += 8;
  }
}
