#include <malloc.h>
#include "dev_dds.h"
#include "board.h"
#include "fonts/font5.h"
#include "itoa.h"
#include <lcd.h>
#include <stdio.h>
#include "dev_keyboard.h"
#include "ui.h"

#define CURSOR_F1 1
#define CURSOR_F2 2
#define CURSOR_F3 3
#define CURSOR_F4 4
#define CURSOR_F5 5
#define CURSOR_F6 6
#define CURSOR_F7 7
#define CURSOR_F8 8
#define CURSOR_F9 9
#define CURSOR_DIV 10
#define CURSOR_V1 11
#define CURSOR_V2 12
#define CURSOR_V3 13
#define CURSOR_V4 14

static unsigned char lastModeKeyEvent;

unsigned char find_next_mode(unsigned char from, unsigned char supported_modes)
{
  unsigned char mode;
  unsigned char mode_code;

  mode_code = (1 << from);
  mode = from;
  while (!(mode_code & supported_modes))
  {
    mode_code <<= 1;
    if (!mode_code)
      return 0xFF;
    mode++;
  }

  return mode;
}

void dds_init_channel_data(dev_dds *ddds)
{
  int i;

  ddds->channel_data = malloc(sizeof(dds_channel) * ddds->cfg.channels);
  if (ddds->channel_data)
  {
    for (i = 0; i < ddds->cfg.channels; i++)
    {
      ddds->channel_data[i].frequency = ddds->default_frequency;
      ddds->channel_data[i].mode = find_next_mode(0, ddds->cfg.supported_modes);
      ddds->channel_data[i].enabled = 0;
      ddds->channel_data[i].output_voltage = ddds->cfg.max_vout_mV;
      ddds->channel_data[i].output_divider_value = 1;
    }
  }
}

static void show_frequency(int x, int y, dds_channel *c)
{
  LcdPrintf("%03d.%06d", x, y, &fiveBySevenFontInfo, 0, c->frequency / 1000000, c->frequency % 1000000);
}

static void show_mode(int x, int y, dds_channel *c)
{
  char s[2];

  s[1] = 0;
  if (!c->enabled)
    s[0] = 'O';
  else
  {
    switch (c->mode)
    {
      case DDS_MODE_SQUARE:
        s[0] = 'Q';
        break;
      case DDS_MODE_SINE:
        s[0] = 'S';
        break;
      default:
        s[0] = 'T';
        break;
    }
  }
  LcdDrawText(x + (fiveBySevenFontInfo.character_max_width + fiveBySevenFontInfo.character_spacing) * 10, y, s, &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, NULL);
}

static void show_divider(int x, int y, unsigned short div, unsigned int swap_colors)
{
  char s[5];
  if (div < 10000)
  {
    itoa(div, s, 10);
    if (!s[1])
      s[1] = ' ';
    s[2] = 0;
    DrawLcdText(x, 11, y, s, &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swap_colors);
  }
  else
    DrawLcdText(x, 11, y, "  ", &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swap_colors);
}

static void show_output_voltage(int x, int y, unsigned short voltage)
{
  char s[5];
  if (voltage < 10000)
  {
    //todo
    //sprintf(s, "%04d", voltage);
    LcdDrawText(x + (fiveBySevenFontInfo.character_max_width + fiveBySevenFontInfo.character_spacing) * 14, y, s, &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, NULL);
  }
}

static void fastShowChannel(int x, int y, dds_channel *c)
{
  show_frequency(x, y, c);
  show_mode(x, y, c);
  show_divider(x, y, c->output_divider_value, 0);
  show_output_voltage(x, y, c->output_voltage);
}

/* LCD layout
 * 000.000000S16 3300
 * S - mode (S = sinus, Q = square, T = triangle, O - off)
 * 000.000000 - frequency
 * 16 - square output divider
 * 3300 - output voltage in mv
 */
void dds_ui_init_handler(int x, int y, int idx, void* config)
{
  dev_dds *dds;
  int i;

  lastModeKeyEvent = 0;

  if (config && !idx)
  {
    dds = (dev_dds *) config;
    if (dds->channel_data)
    {
      for (i = 0; i < dds->cfg.channels; i++)
      {
        fastShowChannel(x, y, &dds->channel_data[i]);
        y += 8;
      }
    }
  }
}

static unsigned int calculateFrequencyCode(unsigned int frequency, unsigned int mclk_MHz, unsigned int accumulator_bits)
{
  return ((unsigned long long int)frequency << accumulator_bits) / (mclk_MHz * 1000000);
}

static void updateFrequency(dev_dds* config, int idx)
{
  dds_cmd command;
  dds_channel* c = &config->channel_data[config->current_channel];
  if (c->enabled)
  {
    command.channel = config->current_channel;
    if (config->cfg.accumulator_bits)
    {
      command.set_frequency_code_command.frequency_code = calculateFrequencyCode(c->frequency, config->cfg.mclk_MHz, config->cfg.accumulator_bits);
      command.set_frequency_code_command.divider = c->output_divider_value;
      config->command(config->deviceId, DDS_COMMAND_SET_FREQUENCY_CODE, &command, idx);
    }
    else
    {
      command.set_frequency_command.frequency = c->frequency;
      command.set_frequency_command.divider = c->output_divider_value;
      config->command(config->deviceId, DDS_COMMAND_SET_FREQUENCY, &command, idx);
    }
  }
}

static unsigned short calculateAttenuatorValue(unsigned short voltage, dds_config* cfg)
{
  return (unsigned short)((unsigned int)voltage * cfg->max_attenuator_value / cfg->max_vout_mV);
}

static void updateAttenuator(dev_dds* config, int idx)
{
  dds_cmd command;
  dds_channel* c = &config->channel_data[config->current_channel];
  if (c->enabled)
  {
    command.channel = config->current_channel;
    command.set_attenuator_command.attenuator_value = calculateAttenuatorValue(c->output_voltage, &config->cfg);
    config->command(config->deviceId, DDS_COMMAND_SET_ATTENUATOR, &command, idx);
  }
}

static void set_next_mode(int x, int y, int idx, dev_dds *config)
{
  unsigned char mode;
  dds_cmd command;
  dds_channel* c = &config->channel_data[config->current_channel];

  command.channel = config->current_channel;
  if (!c->enabled)
  {
    c->enabled = 1;
    command.set_mode_command.mode = c->mode;
    config->command(config->deviceId, DDS_COMMAND_SET_MODE, &command, idx);
    updateFrequency(config, idx);
    updateAttenuator(config, idx);
    command.enable_command.enable = 1;
    config->command(config->deviceId, DDS_COMMAND_ENABLE_OUTPUT, &command, idx);
  }
  else
  {
    mode = find_next_mode(c->mode + 1, config->cfg.supported_modes);
    if (mode == 0xFF)
    {
      c->mode = find_next_mode(0, config->cfg.supported_modes);
      command.enable_command.enable = c->enabled = 0;
      config->command(config->deviceId, DDS_COMMAND_ENABLE_OUTPUT, &command, idx);
    }
    else
    {
      c->mode = mode;
      if (c->enabled)
      {
        command.set_mode_command.mode = mode;
        config->command(config->deviceId, DDS_COMMAND_SET_MODE, &command, idx);
      }
    }
  }
  show_mode(x, y + config->current_channel * 8, c);
}

static void showf1(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F1;
  DrawLcdChar(x, 0, y, '0' + frequency / 100000000, &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf2(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F2;
  DrawLcdChar(x, 1, y, '0' + ((frequency / 10000000) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf3(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F3;
  DrawLcdChar(x, 2, y, '0' + ((frequency / 1000000) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf4(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F4;
  DrawLcdChar(x, 4, y, '0' + ((frequency / 100000) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf5(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F5;
  DrawLcdChar(x, 5, y, '0' + ((frequency / 10000) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf6(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F6;
  DrawLcdChar(x, 6, y, '0' + ((frequency / 1000) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf7(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F7;
  DrawLcdChar(x, 7, y, '0' + ((frequency / 100) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf8(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F8;
  DrawLcdChar(x, 8, y, '0' + ((frequency / 10) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf9(int x, int y, unsigned int frequency)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_F9;
  DrawLcdChar(x, 9, y, '0' + (frequency % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showdiv(int x, int y, unsigned short div)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_DIV;
  show_divider(x, y, div, swapColors);
}

static void showv1(int x, int y, unsigned short v)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_V1;
  DrawLcdChar(x, 14, y, '0' + (v / 1000), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showv2(int x, int y, unsigned short v)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_V2;
  DrawLcdChar(x, 15, y, '0' + ((v / 100) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showv3(int x, int y, unsigned short v)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_V3;
  DrawLcdChar(x, 16, y, '0' + ((v / 10) % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showv4(int x, int y, unsigned short v)
{
  int swapColors = cursorEnabled && cursorPosition == CURSOR_V4;
  DrawLcdChar(x, 17, y, '0' + (v % 10), &fiveBySevenFontInfo, BLACK_COLOR, WHITE_COLOR, swapColors);
}

static void showf(int x, int y, unsigned int frequency)
{
  showf1(x, y, frequency);
  showf2(x, y, frequency);
  showf3(x, y, frequency);
  showf4(x, y, frequency);
  showf5(x, y, frequency);
  showf6(x, y, frequency);
  showf7(x, y, frequency);
  showf8(x, y, frequency);
  showf9(x, y, frequency);
}

static void showv(int x, int y, unsigned short output_voltage)
{
  showv1(x, y, output_voltage);
  showv2(x, y, output_voltage);
  showv3(x, y, output_voltage);
  showv4(x, y, output_voltage);
}

static void showChannel(int x, int y, dds_channel* c)
{
  showf(x, y, c->frequency);
  showdiv(x, y, c->output_divider_value);
  showv(x, y, c->output_voltage);
}

static void showCurrentf(int x, int y, dev_dds* config)
{
  showf(x, y + 8 * config->current_channel, config->channel_data[config->current_channel].frequency);
}

static void showCurrentdiv(int x, int y, dev_dds* config)
{
  showdiv(x, y + 8 * config->current_channel, config->channel_data[config->current_channel].output_divider_value);
}

static void showCurrentv(int x, int y, dev_dds* config)
{
  showv(x, y + 8 * config->current_channel, config->channel_data[config->current_channel].output_voltage);
}

static void showCurrentChannel(int x, int y, dev_dds* config)
{
  showChannel(x, y + 8 * config->current_channel, &config->channel_data[config->current_channel]);
}

static void selectNextChannel(int x, int y, dev_dds* config)
{
  int ch = config->current_channel;
  config->current_channel++;
  if (config->current_channel >= config->cfg.channels)
    config->current_channel = 0;
  fastShowChannel(x, y + 8 * ch, &config->channel_data[ch]);
  showCurrentChannel(x, y, config);
}

static int set_next_divider(dev_dds* config)
{
  unsigned short div = config->channel_data[config->current_channel].output_divider_value << 1;
  if (div <= (1 << ((1 << config->cfg.out_square_divider_bits) - 1)))
  {
    config->channel_data[config->current_channel].output_divider_value = div;
    return 1;
  }
  return 0;
}

static int set_prev_divider(dev_dds* config)
{
  unsigned short div = config->channel_data[config->current_channel].output_divider_value;
  if (div > 1)
  {
    config->channel_data[config->current_channel].output_divider_value = div >> 1;
    return 1;
  }
  return 0;
}

static int frequencyDown(dev_dds* dds)
{
  unsigned int f = dds->channel_data[dds->current_channel].frequency;
  switch (cursorPosition)
  {
  case CURSOR_F1:
    if (f < 100000000)
      return 0;
    f -= 100000000;
    break;
  case CURSOR_F2:
    if (f < 10000000)
      return 0;
    f -= 10000000;
    break;
  case CURSOR_F3:
    if (f < 1000000)
      return 0;
    f -= 1000000;
    break;
  case CURSOR_F4:
    if (f < 100000)
      return 0;
    f -= 100000;
    break;
  case CURSOR_F5:
    if (f < 10000)
      return 0;
    f -= 10000;
    break;
  case CURSOR_F6:
    if (f < 1000)
      return 0;
    f -= 1000;
    break;
  case CURSOR_F7:
    if (f < 100)
      return 0;
    f -= 100;
    break;
  case CURSOR_F8:
    if (f < 10)
      return 0;
    f -= 10;
    break;
  case CURSOR_F9:
    if (f < 1)
      return 0;
    f -= 1;
    break;
  case CURSOR_DIV:
    return set_prev_divider(dds);
    default:
      return 0;
  }
  if (f >= dds->cfg.min_frequency)
  {
    dds->channel_data[dds->current_channel].frequency = f;
    return 1;
  }
  return 0;
}

static int frequencyUp(dev_dds* dds)
{
  unsigned int f = dds->channel_data[dds->current_channel].frequency;
  switch (cursorPosition)
  {
    case CURSOR_F1:
      f += 100000000;
      break;
    case CURSOR_F2:
      f += 10000000;
      break;
    case CURSOR_F3:
      f += 1000000;
      break;
    case CURSOR_F4:
      f += 100000;
      break;
    case CURSOR_F5:
      f += 10000;
      break;
    case CURSOR_F6:
      f += 1000;
      break;
    case CURSOR_F7:
      f += 100;
      break;
    case CURSOR_F8:
      f += 10;
      break;
    case CURSOR_F9:
      f += 1;
      break;
    case CURSOR_DIV:
      return set_next_divider(dds);
    default:
      return 0;
  }
  if (f <= dds->cfg.max_frequency)
  {
    dds->channel_data[dds->current_channel].frequency = f;
    return 1;
  }
  return 0;
}

static int amplitudeDown(dev_dds* dds)
{
  unsigned short v = dds->channel_data[dds->current_channel].output_voltage;
  switch (cursorPosition)
  {
    case CURSOR_V1:
      if (v < 1000)
        return 0;
      v -= 1000;
      break;
    case CURSOR_V2:
      if (v < 100)
        return 0;
      v -= 100;
      break;
    case CURSOR_V3:
      if (v < 10)
        return 0;
      v -= 10;
      break;
    case CURSOR_V4:
      if (v < 1)
        return 0;
      v -= 1;
      break;
    default:
      return 0;
  }
  if (v > 0)
  {
    dds->channel_data[dds->current_channel].output_voltage = v;
    return 1;
  }
  return 0;
}

static int amplitudeUp(dev_dds* dds)
{
  unsigned short v = dds->channel_data[dds->current_channel].output_voltage;
  switch (cursorPosition)
  {
    case CURSOR_V1:
      v += 1000;
      break;
    case CURSOR_V2:
      v += 100;
      break;
    case CURSOR_V3:
      v += 10;
      break;
    case CURSOR_V4:
      v += 1;
      break;
    default:
      return 0;
  }
  if (v <= dds->cfg.max_vout_mV)
  {
    dds->channel_data[dds->current_channel].output_voltage = v;
    return 1;
  }
  return 0;
}

void dds_ui_keyboard_handler(int x, int y, int idx, void *config, unsigned int event)
{
  dev_dds *dds;

  if (config)
  {
    dds = (dev_dds *) config;
    switch (event)
    {
    case KEYBOARD_EVENT_LEAVE:
      showCurrentChannel(x, y, config);
      lastModeKeyEvent = 0;
      break;
    case KEYBOARD_EVENT_KEY2:
      set_next_mode(x, y, idx, dds);
      lastModeKeyEvent = 0;
      break;
    case KEYBOARD_EVENT_KEY3:
      if (!cursorEnabled || cursorPosition > CURSOR_DIV)
      {
        enableCursor(CURSOR_F1);
        showCurrentChannel(x, y, config);
      }
      else
      {
        enableCursor(cursorPosition);
        if (lastModeKeyEvent == event)
          selectNextChannel(x, y, config);
      }
      lastModeKeyEvent = event;
      break;
    case KEYBOARD_EVENT_KEY4:
      if (!cursorEnabled || cursorPosition < CURSOR_V1)
      {
        enableCursor(CURSOR_V1);
        showCurrentChannel(x, y, config);
      }
      else
      {
        enableCursor(cursorPosition);
        if (lastModeKeyEvent == event)
          selectNextChannel(x, y, config);
      }
      lastModeKeyEvent = event;
      break;
    case KEYBOARD_EVENT_KEY5:
      if (cursorEnabled)
      {
        enableCursor(cursorPosition);
        switch (lastModeKeyEvent)
        {
        case KEYBOARD_EVENT_KEY3: // F
          if (cursorPosition <= CURSOR_F1)
            cursorPosition = CURSOR_DIV;
          else
            cursorPosition--;
          showCurrentChannel(x, y, config);
          break;
        case KEYBOARD_EVENT_KEY4: // A
          if (cursorPosition <= CURSOR_V1)
            cursorPosition = CURSOR_V4;
          else
            cursorPosition--;
          showCurrentChannel(x, y, config);
          break;
        }
      }
      break;
    case KEYBOARD_EVENT_KEY6:
      if (cursorEnabled)
      {
        enableCursor(cursorPosition);
        switch (lastModeKeyEvent)
        {
        case KEYBOARD_EVENT_KEY3: // F
          cursorPosition++;
          if (cursorPosition > CURSOR_DIV)
            cursorPosition = CURSOR_F1;
          showCurrentChannel(x, y, config);
          break;
        case KEYBOARD_EVENT_KEY4: // A
          cursorPosition++;
          if (cursorPosition > CURSOR_V4)
            cursorPosition = CURSOR_V1;
          showCurrentChannel(x, y, config);
          break;
        }
      }
      break;
    case KEYBOARD_EVENT_KEY7:
      if (cursorEnabled)
      {
        enableCursor(cursorPosition);
        switch (lastModeKeyEvent)
        {
        case KEYBOARD_EVENT_KEY3: // F
          if (frequencyUp(dds))
          {
            showCurrentf(x, y, config);
            showCurrentdiv(x, y, config);
            updateFrequency(config, idx);
          }
          break;
        case KEYBOARD_EVENT_KEY4: // A
          if (amplitudeUp(dds))
          {
            showCurrentv(x, y, config);
            updateAttenuator(config, idx);
          }
          break;
        }
      }
      break;
    case KEYBOARD_EVENT_KEY8:
      if (cursorEnabled)
      {
        enableCursor(cursorPosition);
        switch (lastModeKeyEvent)
        {
        case KEYBOARD_EVENT_KEY3: // F
          if (frequencyDown(dds))
          {
            showCurrentf(x, y, config);
            showCurrentdiv(x, y, config);
            updateFrequency(config, idx);
          }
          break;
        case KEYBOARD_EVENT_KEY4: // A
          if (amplitudeDown(dds))
          {
            showCurrentv(x, y, config);
            updateAttenuator(config, idx);
          }
          break;
        }
      }
      break;
    }
  }
}

void* dds_initializer(unsigned char deviceId, unsigned int default_frequency, int idx)
{
  int rc;
  dev_dds *cfg = malloc(sizeof(dev_dds));
  if (cfg)
  {
    rc = dds_get_config(&cfg->cfg, deviceId, idx);
    if (rc)
    {
      free(cfg);
      return NULL;
    }
    cfg->deviceId = deviceId;
    cfg->current_channel = 0;
    cfg->command = dds_command;
    cfg->default_frequency = default_frequency;

    dds_init_channel_data(cfg);
  }
  return cfg;
}
