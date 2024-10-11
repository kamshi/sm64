cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/assets/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/capture_output.py
        ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy1
        ${CMAKE_C_COMPILER}
        -o ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy2
        -c -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
        -I${CMAKE_SOURCE_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/include/libc/
        -I${CMAKE_SOURCE_DIR}/src/
        -I${ABSOLUTE_BUILD_DIR}/
        -I${ABSOLUTE_BUILD_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/
        -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1
        -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 -mno-shared
        -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
        -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
        -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
        -ffreestanding -fwrapv -Wall -Wextra -Werror
        ${CMAKE_SOURCE_DIR}/tools/determine-endian-bitwidth.c
    COMMAND grep -o 'msgbegin --endian .* --bitwidth .* msgend' ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy1 > ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy2
    COMMAND head -n1 <${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy2 | cut -d' ' -f2-5 > ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth
    COMMAND rm -f ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy1
    COMMAND rm -f ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth.dummy2
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/tools/capture_output.py ${CMAKE_SOURCE_DIR}/tools/determine-endian-bitwidth.c
    COMMENT "Endian and bitwidth"
)
add_custom_target(endian_and_bitwidth ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth)
