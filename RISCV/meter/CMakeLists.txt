SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_VERSION 1)
cmake_minimum_required(VERSION 3.14)

# specify the cross compiler
SET(CMAKE_C_COMPILER_WORKS 1)

SET(CMAKE_VERBOSE_MAKEFILE ON)

SET(LINKER_SCRIPT ../ldscript.ld)

SET(COMMON_FLAGS "-march=rv32im_zicsr -ffunction-sections -fdata-sections -specs=nosys.specs -specs=nano.specs -nostartfiles")

SET(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS} -std=gnu99")
SET(CMAKE_ASM_FLAGS_INIT "${COMMON_FLAGS} -std=gnu99")
SET(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,-gc-sections,--print-memory-usage -T ${LINKER_SCRIPT}")

project(riscv_meter C ASM)

file(GLOB SOURCES
        "src/*.*"
        "src/devices/*.*"
        "../../ARM_CLION/common_lib/shell/shell.c"
        "../../ARM_CLION/common_lib/fixed_queue.c"
        "../../ARM_CLION/common_lib/myprintf.c"
        "../../ARM_CLION/common_lib/ultoa.c"
        "../../ARM_CLION/common_lib/i2c_soft.c"
        "../../ARM_CLION/common_lib/display/font.c"
        "../../ARM_CLION/common_lib/display/fonts/font5.c"
        "../../ARM_CLION/common_lib/display/lcd.c"
        "../../ARM_CLION/common_lib/display/lcd_ssd1306.c"
        "../../ARM_CLION/common_lib/rf/si5351.c"
        "../../ARM_CLION/common_lib/rf/ad9833.c"
        "../../ARM_CLION/common_lib/sensor/ina226.c"
        "../../ARM_CLION/common_lib/sensor/ina3221.c"
        "../../ARM_CLION/common_lib/sensor/ads1115.c"
        "../../ARM_CLION/common_lib/sensor/mcp3421.c"
        "../../ARM_CLION/common_lib/memory/24c01_16.c")

include_directories(src src/devices
                    ../../ARM_CLION/common_lib ../../ARM_CLION/common_lib/display ../../ARM_CLION/common_lib/shell
                    ../../ARM_CLION/common_lib/sensor ../../ARM_CLION/common_lib/rf ../../ARM_CLION/common_lib/memory)

add_executable(${PROJECT_NAME}.elf ${SOURCES} ${LINKER_SCRIPT})

set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map")
