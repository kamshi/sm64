cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/assets/mario_anim_data.o
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/assets/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/mario_anims_converter.py > ${ABSOLUTE_BUILD_DIR}/assets/mario_anim_data.c
    COMMAND ${CMAKE_C_COMPILER}
        -o ${ABSOLUTE_BUILD_DIR}/assets/mario_anim_data.o
        -MMD -MF ${ABSOLUTE_BUILD_DIR}/assets/mario_anim_data.d
        -c -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
        -I${CMAKE_SOURCE_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/include/libc/
        -I${CMAKE_SOURCE_DIR}/src/
        -I${ABSOLUTE_BUILD_DIR}/
        -I${ABSOLUTE_BUILD_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
        -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1
        -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 -mno-shared
        -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
        -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
        -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
        -ffreestanding -fwrapv -Wall -Wextra -Werror
        ${ABSOLUTE_BUILD_DIR}/assets/mario_anim_data.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/tools/mario_anims_converter.py
    COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/tools/mario_anims_converter.py..."
)
add_custom_target(convert_mario_animations ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/assets/mario_anim_data.o)
