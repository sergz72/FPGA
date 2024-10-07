#include <stddef.h>
#include "device_list.h"
#include "dev_ina3221.h"
#include "dev_ina226.h"
#include "dev_ads1115.h"
#include "dev_ad9833.h"
#include "dev_si5351.h"
#include "dev_mcp3421.h"
#include "dev_dds.h"

#define DDS_MENU_LENGTH 7
const char dds_menu[] = "tfA<>^u";

const Device devices[] = {
    {
        .name = "ina3221",
        .device_id = INA3221_DEVICE_ID,
        .min_devices = 1,
        .max_devices = 3,
        .initializer = ina3221_initializer,
        .data_collector = ina3221_data_collector,
        .ui_init_handler = NULL,
        .ui_data_handler = ina3221_ui_handler,
        .ui_keyboard_handler = NULL,
        .print_config = NULL,
        .set_config = NULL,
        .set_config_parameter_count = 0,
        .set_config_help = NULL,
        .menu_length = 0,
        .menu = NULL
    },
    {
        .name = "ina226",
        .device_id = INA226_DEVICE_ID,
        .min_devices = 1,
        .max_devices = 1,
        .initializer = ina226_initializer,
        .data_collector = ina226_data_collector,
        .ui_init_handler = NULL,
        .ui_data_handler = ina226_ui_handler,
        .ui_keyboard_handler = NULL,
        .print_config = NULL,
        .set_config = NULL,
        .set_config_parameter_count = 0,
        .set_config_help = NULL,
        .menu_length = 0,
        .menu = NULL
    },
    {
        .name = "ads1115",
        .device_id = ADS1115_DEVICE_ID,
        .min_devices = 1,
        .max_devices = 1,
        .initializer = ads1115_initializer,
        .data_collector = ads1115_data_collector,
        .ui_init_handler = NULL,
        .ui_data_handler = ads1115_ui_handler,
        .ui_keyboard_handler = NULL,
        .print_config = NULL,
        .set_config = NULL,
        .set_config_parameter_count = 0,
        .set_config_help = NULL,
        .menu_length = 0,
        .menu = NULL
    },
    {
        .name = "mcp3421",
        .device_id = MCP3421_DEVICE_ID,
        .min_devices = 1,
        .max_devices = 1,
        .initializer = mcp3421_initializer,
        .data_collector = mcp3421_data_collector,
        .ui_init_handler = NULL,
        .ui_data_handler = mcp3421_ui_handler,
        .ui_keyboard_handler = NULL,
        .print_config = msp3421_print_config,
        .set_config = msp3421_set_config,
        .set_config_parameter_count = 2,
        .set_config_help = "coef offset",
        .menu_length = 0,
        .menu = NULL
    },
    {
        .name = "ad9833",
        .device_id = AD9833_DEVICE_ID,
        .min_devices = 2,
        .max_devices = 2,
        .initializer = ad9833_initializer,
        .data_collector = NULL,
        .ui_init_handler = dds_ui_init_handler,
        .ui_data_handler = NULL,
        .ui_keyboard_handler = dds_ui_keyboard_handler,
        .print_config = NULL,
        .set_config = NULL,
        .set_config_parameter_count = 0,
        .set_config_help = NULL,
        .menu_length = DDS_MENU_LENGTH,
        .menu = dds_menu
    },
    {
        .name = "si5351",
        .device_id = SI5351_DEVICE_ID,
        .min_devices = 2,
        .max_devices = 2,
        .initializer = si5351_initializer,
        .data_collector = NULL,
        .ui_init_handler = dds_ui_init_handler,
        .ui_data_handler = NULL,
        .ui_keyboard_handler = dds_ui_keyboard_handler,
        .print_config = NULL,
        .set_config = NULL,
        .set_config_parameter_count = 0,
        .set_config_help = NULL,
        .menu_length = DDS_MENU_LENGTH,
        .menu = dds_menu
    }
};
