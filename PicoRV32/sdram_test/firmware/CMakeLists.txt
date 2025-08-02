SET(CMAKE_SYSTEM_NAME Generic)
SET(CMAKE_SYSTEM_VERSION 1)
cmake_minimum_required(VERSION 3.14)

set(CMAKE_C_STANDARD 23)

# specify the cross compiler
SET(CMAKE_C_COMPILER_WORKS 1)

SET(CMAKE_VERBOSE_MAKEFILE ON)

SET(LINKER_SCRIPT ../../../ldscript.ld)

SET(COMMON_FLAGS "-march=rv32im_zicntr -ffunction-sections -fdata-sections -specs=nosys.specs -specs=nano.specs -nostartfiles")

SET(CMAKE_C_FLAGS_INIT "${COMMON_FLAGS}")
SET(CMAKE_ASM_FLAGS_INIT "${COMMON_FLAGS}")
SET(CMAKE_EXE_LINKER_FLAGS_INIT "-Wl,-gc-sections,--print-memory-usage -T ${LINKER_SCRIPT}")

project(PicoRV32_sdram_test C ASM)

file(GLOB SOURCES
        "src/main.c"
        "src/hal.c"
        "../../start.S"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/shell/shell.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/shell/sdram_commands.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/crypto/chacha.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/getstring.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/fixed_queue.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/common_printf.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/myprintf.c"
        "/home/sergzz/serg/my/Programs/ARM_CLION/common_lib/ultoa.c"
)

include_directories(
        src
        ../..
        /home/sergzz/serg/my/Programs/ARM_CLION/common_lib/shell
        /home/sergzz/serg/my/Programs/ARM_CLION/common_lib/crypto
        /home/sergzz/serg/my/Programs/ARM_CLION/common_lib
)

add_executable(${PROJECT_NAME}.elf ${SOURCES} ${LINKER_SCRIPT})

set(CMAKE_EXE_LINKER_FLAGS
    "${CMAKE_EXE_LINKER_FLAGS} -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map")
