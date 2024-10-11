#include "device_config.h"
#include <24c01_16.h>
#include "board.h"

int read_config_from_eeprom(int idx, void *cfg, int size)
{
  return _24C01_16_read(idx, _24C01_16_address(0), 0, cfg, size, I2C_TIMEOUT);
}

int write_config_to_eeprom(int idx, void *cfg, int size)
{
  return _24C01_16_write(idx, _24C01_16_address(0), 0, cfg, size, I2C_TIMEOUT);
}