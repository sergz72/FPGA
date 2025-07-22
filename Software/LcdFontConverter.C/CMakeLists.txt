cmake_minimum_required(VERSION 3.31)
project(LcdFontConverter C)

set(CMAKE_C_STANDARD 23)

add_executable(LcdFontConverter
        main.c
        ../../my/Programs/ARM_CLION/common_lib/display/fonts/font8_2.c
        ../../my/Programs/ARM_CLION/common_lib/display/fonts/font16.c
)

include_directories(
        ../../my/Programs/ARM_CLION/common_lib/display/fonts
        ../../my/Programs/ARM_CLION/common_lib/display
)

