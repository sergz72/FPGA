#include "board.h"
#include "devices.h"
#include <i2c_soft.h>
#include <ina226.h>
#include <mcp3421.h>
#include <ads1115.h>
#include "dev_dds.h"
#include <si5351.h>
#include "dev_si5351.h"

//todo
void delay(unsigned int us)
{
}

void delayms(unsigned int ms)
{
  while (ms--)
    delay(1000);
}

//todo
void lcd_init(void)
{
}

//todo
void SCL_HIGH(int channel)
{
}

//todo
void SCL_LOW(int channel)
{
}

//todo
void SDA_HIGH(int channel)
{
}

//todo
void SDA_LOW(int channel)
{
}

//todo
int SDA_IN(int channel)
{
  return 1;
}

//todo
int SCL_IN(int channel)
{
  return 1;
}

int I2C_SendAddress(int idx, int address)
{
  i2c_soft_start(idx);

  if (i2c_soft_tx(idx, address, I2C_TIMEOUT)) // no ack
  {
    i2c_soft_stop(idx);
    return 1;
  }

  return 0;
}

int I2CCheck(int idx, int device_id)
{
  int rc;

  rc = I2C_SendAddress(idx, device_id);
  if (!rc)
    i2c_soft_stop(idx);
  return rc == 0;
}

int inaReadRegister(int channel, unsigned char address, unsigned char reg, unsigned short *data)
{
  unsigned char d[2];
  int rc = i2c_soft_command(channel, address, &reg, 1, NULL, 0, d, 2, I2C_TIMEOUT);
  if (!rc)
    *data = (d[0] << 8) | d[1];
  return rc;
}

int ads1115ReadRegister(int channel, unsigned char address, unsigned char reg, unsigned short *data)
{
  return inaReadRegister(channel, address, reg, data);
}

int mcp3421Read(int channel, unsigned char address, unsigned char *data, unsigned int l)
{
  return i2c_soft_read(channel, address, data, l, I2C_TIMEOUT);
}

int inaWriteRegister(int channel, unsigned char address, unsigned char reg, unsigned short data)
{
  unsigned char d[2];
  d[0] = data >> 8;
  d[1] = data & 0xFF;
  return i2c_soft_command(channel, address, &reg, 1, d, 2, NULL, 0, I2C_TIMEOUT);
}

int ads1115WriteRegister(int channel, unsigned char address, unsigned char reg, unsigned short data)
{
  return inaWriteRegister(channel, address, reg, data);
}

int mcp3421Write(int channel, unsigned char address, unsigned char data)
{
  return i2c_soft_command(channel, address, NULL, 0, &data, 1, NULL, 0, I2C_TIMEOUT);
}

int dds_command(unsigned char deviceId, unsigned char cmd, dds_cmd *data, int idx)
{
  dds_i2c_command c;
  switch (cmd)
  {
    case DDS_COMMAND_ENABLE_OUTPUT:
      c.c3.command = cmd;
      c.c3.channel = data->channel;
      c.c3.parameter = data->enable_command.enable;
      return i2c_soft_command(idx, deviceId, (unsigned char*)&c, 3,
                              NULL, 0, NULL, 0, I2C_TIMEOUT);
    case DDS_COMMAND_SET_ATTENUATOR:
      c.c4.command = cmd;
      c.c4.channel = data->channel;
      c.c4.parameter = data->set_attenuator_command.attenuator_value;
      return i2c_soft_command(idx, deviceId, (unsigned char*)&c, 4,
                              NULL, 0, NULL, 0, I2C_TIMEOUT);
    case DDS_COMMAND_SET_FREQUENCY:
      c.c8.command = cmd;
      c.c8.channel = data->channel;
      c.c8.freq = data->set_frequency_command.frequency;
      c.c8.div = data->set_frequency_command.divider;
      return i2c_soft_command(idx, deviceId, (unsigned char*)&c, 8,
                              NULL, 0, NULL, 0, I2C_TIMEOUT);
    case DDS_COMMAND_SET_FREQUENCY_CODE:
      c.c8.command = cmd;
      c.c8.channel = data->channel;
      c.c8.freq = data->set_frequency_code_command.frequency_code;
      c.c8.div = data->set_frequency_code_command.divider;
      return i2c_soft_command(idx, deviceId, (unsigned char*)&c, 8,
                              NULL, 0, NULL, 0, I2C_TIMEOUT);
    case DDS_COMMAND_SET_MODE:
      c.c3.command = cmd;
      c.c3.channel = data->channel;
      c.c3.parameter = data->set_mode_command.mode;
      return i2c_soft_command(idx, deviceId, (unsigned char*)&c, 3,
                              NULL, 0, NULL, 0, I2C_TIMEOUT);
    default:
      return 1;
  }
}

int si5351_write_bulk(int channel, unsigned char addr, unsigned char bytes, unsigned char *data)
{
  return i2c_soft_command(channel, SI5351_DEVICE_ID, &addr, 1, data, bytes, NULL, 0, I2C_TIMEOUT);
}

int si5351_write(int channel, unsigned char addr, unsigned char data)
{
  return i2c_soft_command(channel, SI5351_DEVICE_ID, &addr, 1, &data, 1, NULL, 0, I2C_TIMEOUT);
}

int dds_get_config(dds_config *cfg, unsigned char deviceId, int idx)
{
  return i2c_soft_read(idx, deviceId, (unsigned char*)cfg, sizeof(dds_config), I2C_TIMEOUT);
}

//todo
int SSD1306_I2C_Write(int num_bytes, unsigned char control_byte, unsigned char *buffer)
{
  return 0;
}

