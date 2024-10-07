#include "dev_ad9833.h"
#include "dev_dds.h"

void* ad9833_initializer(int idx)
{
  return dds_initializer(AD9833_DEVICE_ID, 1000000, idx);
}
