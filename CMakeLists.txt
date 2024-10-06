# cmake configuration ---------------------------------------------------------
cmake_minimum_required(VERSION 3.10)
cmake_policy(SET CMP0069 NEW)
set(CMAKE_POLICY_DEFAULT_CMP0069 NEW)

# add subdirectories ----------------------------------------------------------
add_subdirectory(tools)

# define project --------------------------------------------------------------
project(sm64 C)

# set C++ standard ------------------------------------------------------------
#set(CMAKE_CXX_STANDARD 23)
#set(CMAKE_CXX_STANDARD_REQUIRED ON)
#set(CMAKE_CXX_EXTENSIONS OFF)
#
#if(UNIX)
#    add_compile_options(-std=c++2b) # needed by clang-tidy
#endif()

# define useful cmake variables
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    set(USED_COMPILER "gcc")
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    set(USED_COMPILER "clang")
endif()

set(ROM_VERSION "jp" CACHE STRING "ROM version (eu, us, jp, sh)")
set_property(CACHE ROM_VERSION PROPERTY STRINGS "eu" "us" "jp" "sh")

set(ROM_VERSION_STRING "")
if(${ROM_VERSION} STREQUAL "jp")
    set(ROM_VERSION_STRING "VERSION_JP")
elseif(${ROM_VERSION} STREQUAL "eu")
    set(ROM_VERSION_STRING "VERSION_EU")
elseif(${ROM_VERSION} STREQUAL "us")
    set(ROM_VERSION_STRING "VERSION_US")
elseif(${ROM_VERSION} STREQUAL "sh")
    set(ROM_VERSION_STRING "VERSION_SH")
endif()

set(CURRENT_BINARY_DIR ${CMAKE_SOURCE_DIR}/build/${ROM_VERSION})

# set global compiler flags ---------------------------------------------------
if(CMAKE_C_COMPILER_ID STREQUAL "GNU")
    # TODO
    set(GCC_FLAGS -G 0 -nostdinc -mips3 -mno-shared -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks -fno-stack-protector -fno-common -fno-zero-initialized-in-bss -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions -ffreestanding -fwrapv)
    #set(GCC_FLAGS -Wall -Werror -Wconversion -Wno-unknown-pragmas -pedantic -Wno-ignored-optimization-argument)
    add_compile_options(${GCC_FLAGS})
elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang")
    set(CLANG_FLAGS -Wall -Werror -Wno-c++17-extensions -Wconversion -pedantic -Wno-ignored-optimization-argument)
    add_compile_options(${CLANG_FLAGS})
else()
    message(FATAL_ERROR "Your build system is not supported")
endif()

message(STATUS "Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "Compiler version: ${CMAKE_C_COMPILER_VERSION}")
set(COMPILER_VERSION_PARTS ${CMAKE_C_COMPILER_VERSION})
string(REPLACE "." ";" VERSION_LIST ${COMPILER_VERSION_PARTS})
list(GET VERSION_LIST 0 COMPILER_VERSION_MAJOR)
list(GET VERSION_LIST 1 COMPILER_VERSION_MINOR)
list(GET VERSION_LIST 2 COMPILER_VERSION_PATCH)
message(STATUS "Linker: ${CMAKE_LINKER}")

get_filename_component(COMPILER_DIR ${CMAKE_C_COMPILER} DIRECTORY)
message(STATUS "Compiler directory: ${COMPILER_DIR}")

# where executables will be built
set(RUNTIME_OUTPUT_DIRECTORY ${CURRENT_BINARY_DIR})
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${RUNTIME_OUTPUT_DIRECTORY})

# where shared libraries will be built
set(LIBRARY_OUTPUT_DIRECTORY ${CURRENT_BINARY_DIR})
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${LIBRARY_OUTPUT_DIRECTORY})

# where static libraries will be built
set(ARCHIVE_OUTPUT_DIRECTORY ${CURRENT_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${ARCHIVE_OUTPUT_DIRECTORY})

# TODO
set(SM64_COMPILE_DEFINITIONS
    -DNON_MATCHING=1
    -DAVOID_UB=1
    -D_FINALROM=1
    -DTARGET_N64
    -D_LANGUAGE_C
)

if("${ROM_VERSION}" STREQUAL "jp")
    list(APPEND
        SM64_COMPILE_DEFINITIONS
        -DVERSION_JP=1
        -DF3D_OLD=1
    )
    add_compile_options(-g)
    set(GRUCODE f3d_old)
elseif("${ROM_VERSION}" STREQUAL "eu")
    list(APPEND
        SM64_COMPILE_DEFINITIONS
        -DVERSION_EU=1
    )
    add_compile_options(-O2)
    set(GRUCODE f3d_new)
    add_definitions(-DF3D_NEW=1)
elseif("${ROM_VERSION}" STREQUAL "us")
    list(APPEND
        SM64_COMPILE_DEFINITIONS
        -DVERSION_US=1
        -DF3D_OLD=1
    )
    add_compile_options(-g)
    set(GRUCODE f3d_old)
endif()
add_definitions(${SM64_COMPILE_DEFINITIONS})

#ifeq      ($(VERSION),jp)
#  DEFINES   += VERSION_JP=1
#  OPT_FLAGS := -g
#  GRUCODE   ?= f3d_old
#  VERSION_JP_US  ?= true
#  VERSION_SH_CN  ?= false
#else ifeq ($(VERSION),us)
#  DEFINES   += VERSION_US=1
#  OPT_FLAGS := -g
#  GRUCODE   ?= f3d_old
#  VERSION_JP_US  ?= true
#  VERSION_SH_CN  ?= false
#else ifeq ($(VERSION),eu)
  #DEFINES   += VERSION_EU=1
  #add_compile_options(-O2)
  #set(GRUCODE f3d_new)
  #add_definitions(-DF3D_NEW=1)
  #VERSION_JP_US  ?= false
  #VERSION_SH_CN  ?= false
#else ifeq ($(VERSION),sh)
#  DEFINES   += VERSION_SH=1
#  OPT_FLAGS := -O2
#  GRUCODE   ?= f3d_new
#  VERSION_JP_US  ?= false
#  VERSION_SH_CN  ?= true
#else ifeq ($(VERSION),cn)
#  DEFINES   += VERSION_CN=1
#  OPT_FLAGS := -O2
#  GRUCODE   ?= f3d_new
#  VERSION_JP_US ?= false
#  VERSION_SH_CN  ?= true
#endif

# extract assets --------------------------------------------------------------
include(actors_jp.cmake)

add_custom_command(
    OUTPUT ${ASSETS_JP}
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/extract_assets.py ${ROM_VERSION}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/extract_assets.py
    COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/extract_assets.py..."
)

set(CHARMAP charmap.txt)
add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/${CHARMAP}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -DBUILD_DIR=${CURRENT_BINARY_DIR}
            -MMD -MP -MT ${CURRENT_BINARY_DIR}/${CHARMAP}
            -MF ${CURRENT_BINARY_DIR}/${CHARMAP}.d
            -o ${CURRENT_BINARY_DIR}/${CHARMAP}
            ${CMAKE_SOURCE_DIR}/${CHARMAP}
    DEPENDS ${CMAKE_SOURCE_DIR}/${CHARMAP}
    COMMENT "Preprocessing charmap: ${CHARMAP}"
)
add_custom_target(preprocess_charmap ALL DEPENDS ${CURRENT_BINARY_DIR}/${CHARMAP})

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/charmap.debug.txt
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -DBUILD_DIR=${CURRENT_BINARY_DIR}
            -MMD -MP -MT ${CURRENT_BINARY_DIR}/charmap.debug.txt
            -MF ${CURRENT_BINARY_DIR}/charmap.debug.txt.d
            -o ${CURRENT_BINARY_DIR}/charmap.debug.txt
            ${CMAKE_SOURCE_DIR}/${CHARMAP}
    DEPENDS ${CMAKE_SOURCE_DIR}/${CHARMAP}
    COMMENT "Preprocessing charmap: charmap.debug.txt"
)
add_custom_target(preprocess_charmap_debug ALL DEPENDS ${CURRENT_BINARY_DIR}/charmap.debug.txt)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/text/${ROM_VERSION}/define_text.inc.c
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/text/${ROM_VERSION}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            ${CMAKE_SOURCE_DIR}/text/define_text.inc.c -o ${CURRENT_BINARY_DIR}/define_text.inc.c.temp -I ${CMAKE_SOURCE_DIR}/text/${ROM_VERSION}/
    COMMAND ${CMAKE_SOURCE_DIR}/tools/textconv ${CURRENT_BINARY_DIR}/${CHARMAP} ${CURRENT_BINARY_DIR}/define_text.inc.c.temp ${CURRENT_BINARY_DIR}/text/${ROM_VERSION}/define_text.inc.c
    DEPENDS ${CMAKE_SOURCE_DIR}/text/define_text.inc.c textconv
    COMMENT "Preprocessing define_text.inc.c"
)
add_custom_target(preprocess_define_text.inc.c ALL DEPENDS ${CURRENT_BINARY_DIR}/text/${ROM_VERSION}/define_text.inc.c)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/text/debug_text.raw.inc.c
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/text/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            ${CMAKE_SOURCE_DIR}/text/debug_text.inc.c -o ${CURRENT_BINARY_DIR}/debug_text.inc.c.temp -I ${CMAKE_SOURCE_DIR}/text/
    COMMAND ${CMAKE_SOURCE_DIR}/tools/textconv ${CURRENT_BINARY_DIR}/charmap.debug.txt ${CURRENT_BINARY_DIR}/debug_text.inc.c.temp ${CURRENT_BINARY_DIR}/text/debug_text.raw.inc.c
    DEPENDS ${CMAKE_SOURCE_DIR}/text/debug_text.inc.c textconv
    COMMENT "Preprocessing debug_text.inc.c"
)
add_custom_target(preprocess_debug_text.inc.c ALL DEPENDS ${CURRENT_BINARY_DIR}/text/debug_text.raw.inc.c)

set(LEVEL_RULES_MK levels/level_rules.mk)
add_custom_command(
    OUTPUT ${CMAKE_SOURCE_DIR}/level_rules.mk
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -o ${CURRENT_BINARY_DIR}/level_rules.mk
            ${CMAKE_SOURCE_DIR}/${LEVEL_RULES_MK}
    DEPENDS ${CMAKE_SOURCE_DIR}/${LEVEL_RULES_MK}
    COMMENT "Preprocessing level rules: ${LEVEL_RULES_MK}"
)
add_custom_target(preprocess_level_rules ALL DEPENDS ${CMAKE_SOURCE_DIR}/level_rules.mk)

set(LEVEL_RULES_MK levels/level_rules.mk)
add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/sm64.ld
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -DBUILD_DIR=build/${ROM_VERSION}
            -MMD -MP -MT ${CURRENT_BINARY_DIR}/sm64.ld
            -MF ${CURRENT_BINARY_DIR}/sm64.ld.d
            -o ${CURRENT_BINARY_DIR}/sm64.ld
            ${CMAKE_SOURCE_DIR}/sm64.ld
    DEPENDS ${CMAKE_SOURCE_DIR}/${LEVEL_RULES_MK}
    COMMENT "Preprocessing sm64.ld"
)
add_custom_target(preprocess_sm64.ld ALL DEPENDS ${CURRENT_BINARY_DIR}/sm64.ld)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/level_headers.h.temp
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            ${CMAKE_SOURCE_DIR}/levels/level_headers.h.in > ${CURRENT_BINARY_DIR}/level_headers.h.temp
    DEPENDS ${CMAKE_SOURCE_DIR}/levels/level_headers.h.in
    COMMENT "Preprocessing level headers: levels/level_headers.h.in"
)
add_custom_target(preprocess_level_headers_temp ALL DEPENDS ${CURRENT_BINARY_DIR}/level_headers.h.temp)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/include/level_headers.h
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/include/
    COMMAND $<TARGET_FILE:generate_level_header> ${CURRENT_BINARY_DIR}/level_headers.h.temp ${CURRENT_BINARY_DIR}/include/level_headers.h
    DEPENDS ${CURRENT_BINARY_DIR}/level_headers.h.temp generate_level_header
    COMMENT "Generating level_headers.h from ${TEMP_FILE} using generate_level_header..."
)
add_custom_target(generate_level_headers ALL DEPENDS ${CURRENT_BINARY_DIR}/include/level_headers.h)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/include/text_strings.h
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/include/
    COMMAND ${CMAKE_SOURCE_DIR}/tools/textconv ${CURRENT_BINARY_DIR}/${CHARMAP} ${CMAKE_SOURCE_DIR}/include/text_strings.h.in ${CURRENT_BINARY_DIR}/include/text_strings.h
    DEPENDS ${CURRENT_BINARY_DIR}/${CHARMAP} ${CMAKE_SOURCE_DIR}/include/text_strings.h.in textconv
    COMMENT "Generating text_strings.h from textconv..."
)
add_custom_target(generate_text_strings ALL DEPENDS ${CURRENT_BINARY_DIR}/include/text_strings.h)
add_dependencies(generate_text_strings textconv)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/include/text_menu_strings.h
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/include/
    COMMAND ${CMAKE_SOURCE_DIR}/tools/textconv ${CURRENT_BINARY_DIR}/${CHARMAP} ${CMAKE_SOURCE_DIR}/include/text_menu_strings.h.in ${CURRENT_BINARY_DIR}/include/text_menu_strings.h
    DEPENDS ${CURRENT_BINARY_DIR}/${CHARMAP} ${CMAKE_SOURCE_DIR}/include/text_menu_strings.h.in textconv
    COMMENT "Generating text_strings.h from textconv..."
)
add_custom_target(generate_text_menu_strings ALL DEPENDS ${CURRENT_BINARY_DIR}/include/text_menu_strings.h)
add_dependencies(generate_text_menu_strings textconv)

# run assembler ---------------------------------------------------------------
add_custom_target(assemble_files)
macro(assemble_file INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
                -I${CMAKE_SOURCE_DIR}/include
                -I${CURRENT_BINARY_DIR}
                -I${CURRENT_BINARY_DIR}/include
                -I${CMAKE_SOURCE_DIR}/src
                -I${CMAKE_SOURCE_DIR}
                -I${CMAKE_SOURCE_DIR}/include/libc
                -D${ROM_VERSION_STRING}=1
                # TODO
                -DF3D_OLD=1
                -DNON_MATCHING=1
                -DAVOID_UB=1
                -D_FINALROM=1
                -o ${OUTPUT_FILE}.temp
                ${INPUT_FILE}
        COMMAND mips-linux-gnu-as
                -march=vr4300 -mabi=32
                -I${CMAKE_SOURCE_DIR}/include
                -I${CURRENT_BINARY_DIR}
                -I${CURRENT_BINARY_DIR}/include
                -I${CMAKE_SOURCE_DIR}/src
                -I${CMAKE_SOURCE_DIR}
                -I${CMAKE_SOURCE_DIR}/include/libc
                --defsym ${ROM_VERSION_STRING}=1
                # TODO: defsym
                --defsym F3D_OLD=1
                --defsym NON_MATCHING=1
                --defsym AVOID_UB=1
                --defsym _FINALROM=1
                -MD ${OUTPUT_FILE}.d
                -o ${OUTPUT_FILE}
                ${OUTPUT_FILE}.temp
        DEPENDS ${INPUT_FILE}
        COMMENT "Assembling file ${INPUT_FILE}"
    )
    string(REPLACE "/" "_" TARGET_NAME "assemble${INPUT_FILE}")
    add_custom_target(${TARGET_NAME} ALL DEPENDS ${OUTPUT_FILE})
    add_dependencies(assemble_files ${TARGET_NAME})
endmacro()


file(GLOB ASSEMBLY_FILES "${CMAKE_SOURCE_DIR}/asm/*.s")
foreach(ASSEMBLY_FILE ${ASSEMBLY_FILES})
    get_filename_component(OUTPUT_DIR "${ASSEMBLY_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${ASSEMBLY_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
    assemble_file(${ASSEMBLY_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.o")
endforeach()

file(GLOB LIB_ASSEMBLY_FILES "${CMAKE_SOURCE_DIR}/lib/asm/*.s")
foreach(ASSEMBLY_FILE ${LIB_ASSEMBLY_FILES})
    get_filename_component(OUTPUT_DIR "${ASSEMBLY_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${ASSEMBLY_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
    assemble_file(${ASSEMBLY_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.o")
endforeach()

add_custom_target(armips_files)
macro(armips_file INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}.s" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)

    add_custom_command(
        OUTPUT ${OUTPUT_DIR}/${OUTPUT_FILENAME}.bin
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/armips
        -sym ${OUTPUT_DIR}/${OUTPUT_FILENAME}.bin.sym
        # TODO
        -definelabel ${ROM_VERSION_STRING} 1
        -definelabel F3D_OLD 1
        -definelabel NON_MATCHING 1
        -definelabel AVOID_UB 1
        -definelabel _FINALROM 1
        -strequ CODE_FILE
        ${OUTPUT_DIR}/${OUTPUT_FILENAME}.bin
        -strequ DATA_FILE
        ${OUTPUT_DIR}/${OUTPUT_FILENAME}_data.bin
        ${INPUT_FILE}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        DEPENDS armips ${INPUT_FILE}
        COMMENT "Assembling file ${INPUT_FILE}"
    )
    add_custom_target(armips_${OUTPUT_FILENAME} ALL DEPENDS ${OUTPUT_DIR}/${OUTPUT_FILENAME}.bin)
    add_dependencies(assemble_files armips_${OUTPUT_FILENAME})
endmacro()

file(GLOB RSP_ASSEMBLY_FILES "${CMAKE_SOURCE_DIR}/rsp/*.s")
foreach(ASSEMBLY_FILE ${RSP_ASSEMBLY_FILES})
    get_filename_component(OUTPUT_DIR "${ASSEMBLY_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${ASSEMBLY_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
    armips_file(${ASSEMBLY_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
endforeach()

assemble_file("${CMAKE_SOURCE_DIR}/lib/rsp.s" "${CURRENT_BINARY_DIR}/lib/rsp.o")

# convert animations ----------------------------------------------------------
add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/assets/mario_anim_data.o
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/assets/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/mario_anims_converter.py > ${CURRENT_BINARY_DIR}/assets/mario_anim_data.c
    COMMAND ${CMAKE_C_COMPILER}
        -o ${CURRENT_BINARY_DIR}/assets/mario_anim_data.o
        -MMD -MF ${CURRENT_BINARY_DIR}/assets/mario_anim_data.d
        -c -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
        -I${CMAKE_SOURCE_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/include/libc/
        -I${CMAKE_SOURCE_DIR}/src/
        -I${CURRENT_BINARY_DIR}/
        -I${CURRENT_BINARY_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
        -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1
        -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 -mno-shared
        -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
        -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
        -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
        -ffreestanding -fwrapv -Wall -Wextra -Werror
        ${CURRENT_BINARY_DIR}/assets/mario_anim_data.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/tools/mario_anims_converter.py
    COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/tools/mario_anims_converter.py..."
)
add_custom_target(convert_mario_animations ALL DEPENDS ${CURRENT_BINARY_DIR}/assets/mario_anim_data.o)

# convert demo data -----------------------------------------------------------
add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/assets/demo_data.o
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/assets/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/demo_data_converter.py
        assets/demo_data.json
        -Iinclude
        -Ibuild/${ROM_VERSION}
        -Ibuild/${ROM_VERSION}/include
        -Isrc
        -I.
        -Iinclude/libc
        -D${ROM_VERSION_STRING}=1
        -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 # TODO
        > ${CURRENT_BINARY_DIR}/assets/demo_data.c
    COMMAND ${CMAKE_C_COMPILER}
        -o ${CURRENT_BINARY_DIR}/assets/demo_data.o
        -MMD -MF ${CURRENT_BINARY_DIR}/assets/demo_data.d
        -c -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
        -I${CMAKE_SOURCE_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/include/libc/
        -I${CMAKE_SOURCE_DIR}/src/
        -I${CURRENT_BINARY_DIR}/
        -I${CURRENT_BINARY_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
        -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1
        -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 -mno-shared
        -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
        -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
        -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
        -ffreestanding -fwrapv -Wall -Wextra -Werror
        ${CURRENT_BINARY_DIR}/assets/demo_data.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/tools/demo_data_converter.py
    COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/tools/demo_data_converter.py..."
)
add_custom_target(convert_demo_data ALL DEPENDS ${CURRENT_BINARY_DIR}/assets/demo_data.o)

# convert sounds --------------------------------------------------------------
add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/endian-and-bitwidth
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/assets/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/capture_output.py
        ${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy1
        ${CMAKE_C_COMPILER}
        -o ${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy2
        -c -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
        -I${CMAKE_SOURCE_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/include/libc/
        -I${CMAKE_SOURCE_DIR}/src/
        -I${CURRENT_BINARY_DIR}/
        -I${CURRENT_BINARY_DIR}/include/
        -I${CMAKE_SOURCE_DIR}/
        -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1
        -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 -mno-shared
        -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
        -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
        -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
        -ffreestanding -fwrapv -Wall -Wextra -Werror
        ${CMAKE_SOURCE_DIR}/tools/determine-endian-bitwidth.c
    COMMAND grep -o 'msgbegin --endian .* --bitwidth .* msgend' ${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy1 > ${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy2
    COMMAND head -n1 <${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy2 | cut -d' ' -f2-5 > ${CURRENT_BINARY_DIR}/endian-and-bitwidth
    COMMAND rm -f ${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy1
    COMMAND rm -f ${CURRENT_BINARY_DIR}/endian-and-bitwidth.dummy2
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/tools/capture_output.py ${CMAKE_SOURCE_DIR}/tools/determine-endian-bitwidth.c
    COMMENT "Endian and bitwidth"
)
add_custom_target(endian_and_bitwidth ALL DEPENDS ${CURRENT_BINARY_DIR}/endian-and-bitwidth)

add_custom_target(encode_sounds)
macro(encode_sound INPUT_FILE)
    get_filename_component(OUTPUT_DIR "${INPUT_FILE}" DIRECTORY)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
    get_filename_component(OUTPUT_FILENAME "${INPUT_FILE}" NAME_WLE)
    string(REPLACE "#" "_sharp_" MODIFIED_FILENAME "${OUTPUT_FILENAME}")

    if(${MODIFIED_FILENAME} STREQUAL ${OUTPUT_FILENAME})
        add_custom_command(
            OUTPUT ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/
            COMMAND ${CMAKE_SOURCE_DIR}/tools/aiff_extract_codebook ${INPUT_FILE} >${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.table
            COMMAND ${CMAKE_SOURCE_DIR}/tools/vadpcm_enc -c ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.table ${INPUT_FILE} ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            DEPENDS aiff_extract_codebook vadpcm_enc
            COMMENT "Encoding sound ${INPUT_FILE} -> ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc"
        )
    else()
        # hack: cmake output can't contain #, so we generate an additional file not containing the #
        add_custom_command(
            OUTPUT ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/
            COMMAND ${CMAKE_SOURCE_DIR}/tools/aiff_extract_codebook ${INPUT_FILE} >${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.table
            COMMAND ${CMAKE_SOURCE_DIR}/tools/vadpcm_enc -c ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.table ${INPUT_FILE} ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            COMMAND ${CMAKE_COMMAND} -E copy "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc" "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}.aifc"
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            DEPENDS aiff_extract_codebook vadpcm_enc
            COMMENT "Encoding sound ${INPUT_FILE} -> ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc"
        )
    endif()

    string(REPLACE "/" "_" TARGET_NAME "encode_sound${RELATIVE_PATH}/${MODIFIED_FILENAME}")
    add_custom_target(${TARGET_NAME} ALL DEPENDS ${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc)
    add_dependencies(encode_sounds ${TARGET_NAME})
endmacro()

set(SOUNDS_DIR ${CMAKE_SOURCE_DIR}/sound/samples)
file(GLOB_RECURSE SOUND_FILES "${SOUNDS_DIR}/*.aiff")
foreach(SOUND_FILE ${SOUND_FILES})
    get_filename_component(OUTPUT_DIR "${SOUND_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${SOUND_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
    encode_sound(${OUTPUT_DIR}/${OUTPUT_FILENAME}.aiff)
endforeach()

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/sound/sound_data.ctl.inc.c
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/sound/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
        ${CURRENT_BINARY_DIR}/sound/samples/
        ${CMAKE_SOURCE_DIR}/sound/sound_banks/
        ${CURRENT_BINARY_DIR}/sound/sound_data.ctl
        ${CURRENT_BINARY_DIR}/sound/ctl_header
        ${CURRENT_BINARY_DIR}/sound/sound_data.tbl
        ${CURRENT_BINARY_DIR}/sound/tbl_header
        -D${ROM_VERSION_STRING}=1
        -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 # TODO
        "$(cat ${CURRENT_BINARY_DIR}/endian-and-bitwidth)"
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${CURRENT_BINARY_DIR}/sound/sound_data.ctl > ${CURRENT_BINARY_DIR}/sound/sound_data.ctl.inc.c
    COMMAND echo >> ${CURRENT_BINARY_DIR}/sound/sound_data.ctl.inc.c
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${CURRENT_BINARY_DIR}/sound/sound_data.tbl > ${CURRENT_BINARY_DIR}/sound/sound_data.tbl.inc.c
    COMMAND echo >> ${CURRENT_BINARY_DIR}/sound/sound_data.tbl.inc.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CURRENT_BINARY_DIR}/endian-and-bitwidth ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
    COMMENT "Converting sounds"
)
add_custom_target(convert_sounds ALL DEPENDS ${CURRENT_BINARY_DIR}/sound/sound_data.ctl.inc.c)

add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.m64
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/sound/sequences/
    COMMAND clang
        -E -P -x c
        -Wno-trigraphs
        -D_LANGUAGE_ASSEMBLY
        -I${CMAKE_SOURCE_DIR}/include
        -I${CURRENT_BINARY_DIR}
        -I${CURRENT_BINARY_DIR}/include
        -I${CMAKE_SOURCE_DIR}/src
        -I${CMAKE_SOURCE_DIR}
        -I${CMAKE_SOURCE_DIR}/include/libc
        -D${ROM_VERSION_STRING}=1
        # TODO
        -DF3D_OLD=1
        -DNON_MATCHING=1
        -DAVOID_UB=1
        -D_FINALROM=1
        -o ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.temp
        ${CMAKE_SOURCE_DIR}/sound/sequences/00_sound_player.s
    COMMAND mips-linux-gnu-as
            -march=vr4300 -mabi=32
            -I${CMAKE_SOURCE_DIR}/include
            -I${CURRENT_BINARY_DIR}
            -I${CURRENT_BINARY_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            --defsym ${ROM_VERSION_STRING}=1
            # TODO: defsym
            --defsym F3D_OLD=1
            --defsym NON_MATCHING=1
            --defsym AVOID_UB=1
            --defsym _FINALROM=1
            -MD ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.d
            -o ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.o
            ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.temp
    COMMAND mips-linux-gnu-objcopy # TODO: use variable
        -j .rodata
        ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.o
        -O binary
        ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.m64
    DEPENDS ${CMAKE_SOURCE_DIR}/sound/sequences/00_sound_player.s
    COMMENT "Assembling: sound/sequences/00_sound_player.s -> ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.m64"
)
add_custom_target(assemble_sound_player ALL DEPENDS ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.m64)


add_custom_command(
    OUTPUT ${CURRENT_BINARY_DIR}/sound/bank_sets.inc.c
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/sound/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
        --sequences
        ${CURRENT_BINARY_DIR}/sound/sequences.bin
        ${CURRENT_BINARY_DIR}/sound/sequences_header
        ${CURRENT_BINARY_DIR}/sound/bank_sets sound/sound_banks/
        ${CMAKE_SOURCE_DIR}/sound/sequences.json
        ${CURRENT_BINARY_DIR}/sound/sequences/00_sound_player.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/1D_event_peach_message.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/1A_cutscene_credits.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/0D_menu_star_select.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/03_level_grass.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/02_menu_title_screen.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/11_level_koopa_road.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/14_event_race.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/1B_event_solve_puzzle.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/05_level_water.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/12_event_high_score.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/16_event_boss.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/09_level_slide.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/18_event_endless_stairs.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/13_event_merry_go_round.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/15_cutscene_star_spawn.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/08_level_snow.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/19_level_boss_koopa_final.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/04_level_inside_castle.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/20_cutscene_ending.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/06_level_hot.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/17_cutscene_collect_key.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/10_event_koopa_message.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/07_level_boss_koopa.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/1E_cutscene_intro.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/0B_event_piranha_plant.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/1C_event_toad_message.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/0A_level_spooky.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/21_menu_file_select.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/0E_event_powerup.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/01_cutscene_collect_star.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/0F_event_metal_cap.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/1F_cutscene_victory.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/jp/0C_level_underground.m64
        -D${ROM_VERSION_STRING}=1
        -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 # TODO
        "$(cat ${CURRENT_BINARY_DIR}/endian-and-bitwidth)"
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${CURRENT_BINARY_DIR}/sound/sequences.bin > ${CURRENT_BINARY_DIR}/sound/sequences.bin.inc.c
    COMMAND echo >> ${CURRENT_BINARY_DIR}/sound/sequences.bin.inc.c
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${CURRENT_BINARY_DIR}/sound/bank_sets > ${CURRENT_BINARY_DIR}/sound/bank_sets.inc.c
    COMMAND echo >> ${CURRENT_BINARY_DIR}/sound/bank_sets.inc.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CURRENT_BINARY_DIR}/endian-and-bitwidth ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
    COMMENT "Converting sounds"
)
add_custom_target(convert_sequences ALL DEPENDS ${CURRENT_BINARY_DIR}/sound/bank_sets.inc.c)

# convert textures ------------------------------------------------------------
add_custom_target(convert_textures)

macro(convert_texture_ia1 INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}.inc.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics
                -s u8
                -i ${OUTPUT_FILE}.inc.c
                -g ${INPUT_FILE}
                -f ia1
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}.inc.c"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE}.inc.c)
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

macro(convert_crash_texture_ia1 INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}.inc.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics
                -s u32
                -i ${OUTPUT_FILE}.inc.c
                -g ${INPUT_FILE}
                -f ia1
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}.inc.c"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE}.inc.c)
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

macro(convert_texture_ia1_raw INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics
                -s raw
                -i ${OUTPUT_FILE}
                -g ${INPUT_FILE}
                -f ia1
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE})
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

macro(convert_texture_ia4 INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}.inc.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics
                -s u8
                -i ${OUTPUT_FILE}.inc.c
                -g ${INPUT_FILE}
                -f ia4
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}.inc.c"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE}.inc.c)
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

macro(convert_texture_ia8 INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
    add_custom_command(
        OUTPUT ${OUTPUT_FILE}.inc.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics -s u8 -i ${OUTPUT_FILE}.inc.c -g ${INPUT_FILE} -f ia8
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}.inc.c"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE}.inc.c)
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

macro(convert_texture_ia16 INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}.inc.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics
                -s u8
                -i ${OUTPUT_FILE}.inc.c
                -g ${INPUT_FILE}
                -f ia16
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}.inc.c"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE}.inc.c)
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

macro(convert_texture_rgba16 INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}.inc.c
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/n64graphics
                -s u8
                -i ${OUTPUT_FILE}.inc.c
                -g ${INPUT_FILE}
                -f rgba16
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting texture: ${INPUT_FILE} -> ${OUTPUT_FILE}.inc.c"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_texture${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE}.inc.c)
    add_dependencies(${TARGET_NAME} n64graphics)
    add_dependencies(convert_textures ${TARGET_NAME})
endmacro()

set(TEXTURE_DIR ${CMAKE_SOURCE_DIR}/actors)
file(GLOB_RECURSE PNG_FILES "${TEXTURE_DIR}/*.png")
foreach(PNG_FILE ${PNG_FILES})
    get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    string(REGEX MATCH ".*ipl3_raw.*" IS_RAW ${OUTPUT_DIR})
    if(IS_RAW)
        convert_texture_ia1_raw(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    else()
        string(REGEX MATCH ".*\.ia1.png" IS_IA1 ${PNG_FILE})
        if(IS_IA1)
            # special case for a single texture
            string(REGEX MATCH ".*crash_screen_font\.ia1\.png" IS_CRASH_TEXTURE ${PNG_FILE})
            if(IS_CRASH_TEXTURE)
                convert_crash_texture_ia1(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
            else()
                convert_texture_ia1(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
            endif()
        else()
            string(REGEX MATCH ".*\.ia4.png" IS_IA4 ${PNG_FILE})
            if(IS_IA4)
                convert_texture_ia4(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
            else()
                string(REGEX MATCH ".*\.ia8.png" IS_IA8 ${PNG_FILE})
                if(IS_IA8)
                    convert_texture_ia8(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                else()
                    string(REGEX MATCH ".*\.ia16.png" IS_IA16 ${PNG_FILE})
                    if(IS_IA16)
                        convert_texture_ia16(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                    else()
                        convert_texture_rgba16(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                    endif()
                endif()
            endif()
        endif()
    endif()
endforeach()

set(TEXTURE_DIRECTORIES
    textures/cave
    textures/crash_screen
    textures/effect
    textures/fire
    textures/generic
    textures/grass
    textures/inside
    textures/intro_raw
    textures/ipl3_raw
    textures/machine
    textures/mountain
    textures/outside
    textures/segment2
    textures/sky
    textures/snow
    textures/spooky
    textures/title_screen_bg
    textures/water
)

# TODO: the textures get extracted when running cmake for the first time, so this does not work properly
foreach(TEXTURE_DIRECTORY ${TEXTURE_DIRECTORIES})
    file(GLOB PNG_FILES "${TEXTURE_DIRECTORY}/*.png")
    foreach(PNG_FILE ${PNG_FILES})
        get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
        get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

        string(REGEX MATCH ".*ipl3_raw.*" IS_RAW ${OUTPUT_DIR})
        if(IS_RAW)
            convert_texture_ia1_raw(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
        else()
            string(REGEX MATCH ".*\.ia1.png" IS_IA1 ${PNG_FILE})
            if(IS_IA1)
                # special case for a single texture
                string(REGEX MATCH ".*crash_screen_font\.ia1\.png" IS_CRASH_TEXTURE ${PNG_FILE})
                if(IS_CRASH_TEXTURE)
                    convert_crash_texture_ia1(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                else()
                    convert_texture_ia1(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                endif()
            else()
                string(REGEX MATCH ".*\.ia4.png" IS_IA4 ${PNG_FILE})
                if(IS_IA4)
                    convert_texture_ia4(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                else()
                    string(REGEX MATCH ".*\.ia8.png" IS_IA8 ${PNG_FILE})
                    if(IS_IA8)
                        convert_texture_ia8(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                    else()
                        string(REGEX MATCH ".*\.ia16.png" IS_IA16 ${PNG_FILE})
                        if(IS_IA16)
                            convert_texture_ia16(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                        else()
                            convert_texture_rgba16(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                        endif()
                    endif()
                endif()
            endif()
        endif()
    endforeach()
endforeach()

set(LEVEL_DIRECTORIES
    levels/bbh/
    levels/bitdw/
    levels/bitfs/
    levels/bits/
    levels/bob/
    levels/bowser_1/
    levels/bowser_2/
    levels/bowser_3/
    levels/castle_courtyard/
    levels/castle_grounds/
    levels/castle_inside/
    levels/ccm/
    levels/cotmc/
    levels/ddd/
    #levels/ending/ # TODO: processed separately
    levels/hmc/
    levels/intro/
    levels/jrb/
    levels/lll/
    levels/menu/
    levels/pss/
    levels/rr/
    levels/sa/
    levels/sl/
    levels/ssl/
    levels/thi/
    levels/totwc/
    levels/ttc/
    levels/ttm/
    levels/vcutm/
    levels/wdw/
    levels/wf/
    levels/wmotr/
)

foreach(LEVEL_DIRECTORY ${LEVEL_DIRECTORIES})
    file(GLOB PNG_FILES "${LEVEL_DIRECTORY}/*.png")

    foreach(PNG_FILE ${PNG_FILES})
        get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
        get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

        string(REGEX MATCH ".*ipl3_raw.*" IS_RAW ${OUTPUT_DIR})
        if(IS_RAW)
            convert_texture_ia1_raw(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
        else()
            string(REGEX MATCH ".*\.ia1.png" IS_IA1 ${PNG_FILE})
            if(IS_IA1)
                # special case for a single texture
                string(REGEX MATCH ".*crash_screen_font\.ia1\.png" IS_CRASH_TEXTURE ${PNG_FILE})
                if(IS_CRASH_TEXTURE)
                    convert_crash_texture_ia1(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                else()
                    convert_texture_ia1(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                endif()
            else()
                string(REGEX MATCH ".*\.ia4.png" IS_IA4 ${PNG_FILE})
                if(IS_IA4)
                    convert_texture_ia4(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                else()
                    string(REGEX MATCH ".*\.ia8.png" IS_IA8 ${PNG_FILE})
                    if(IS_IA8)
                        convert_texture_ia8(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                    else()
                        string(REGEX MATCH ".*\.ia16.png" IS_IA16 ${PNG_FILE})
                        if(IS_IA16)
                            convert_texture_ia16(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                        else()
                            convert_texture_rgba16(${PNG_FILE} "${CURRENT_BINARY_DIR}${RELATIVE_PATH}/${OUTPUT_FILENAME}")
                        endif()
                    endif()
                endif()
            endif()
        endif()
    endforeach()
endforeach()

# skyboxes --------------------------------------------------------------------
add_custom_target(convert_skyboxes)
macro(convert_skybox INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/skyconv
        --type sky
        --split ${INPUT_FILE}
        ${OUTPUT_DIR}
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting skybox: ${INPUT_FILE} -> ${OUTPUT_FILE}"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_skybox${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE})
    add_dependencies(${TARGET_NAME} skyconv)
    add_dependencies(convert_skyboxes ${TARGET_NAME})
endmacro()

set(SKYBOX_DIRECTORIES
    textures/skyboxes
)

foreach(SKYBOX_DIRECTORY ${SKYBOX_DIRECTORIES})
    file(GLOB PNG_FILES "${SKYBOX_DIRECTORY}/*.png")
    foreach(PNG_FILE ${PNG_FILES})
        get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
        get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
        convert_skybox(${PNG_FILE} "${CURRENT_BINARY_DIR}/bin/${OUTPUT_FILENAME}_skybox")
    endforeach()
endforeach()

# cakes -----------------------------------------------------------------------
add_custom_target(convert_cakes)
macro(convert_cake INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/skyconv
        --type cake
        --split ${INPUT_FILE}
        ${OUTPUT_DIR}
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting cake: ${INPUT_FILE} -> ${OUTPUT_FILE}"
    )
    string(REPLACE "/" "_" TARGET_NAME "convert_cake${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OUTPUT_FILE})
    add_dependencies(${TARGET_NAME} skyconv)
    add_dependencies(convert_cakes ${TARGET_NAME})
endmacro()

set(CAKE_DIRECTORIES
    levels/ending
)

foreach(CAKE_DIRECTORY ${CAKE_DIRECTORIES})
    file(GLOB PNG_FILES "${CAKE_DIRECTORY}/*.png")
    foreach(PNG_FILE ${PNG_FILES})
        get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
        get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
        string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")
        convert_cake(${PNG_FILE} "${CURRENT_BINARY_DIR}/levels/ending/${OUTPUT_FILENAME}.inc.c")
    endforeach()
endforeach()

set(SM64_AUDIO_HEADERS
    src/audio/data.h
    src/audio/effects.h
    src/audio/external.h
    src/audio/heap.h
    src/audio/internal.h
    src/audio/load.h
    src/audio/playback.h
    src/audio/seqplayer.h
    src/audio/synthesis.h
)

set(SM64_BUFFERS_HEADERS
    src/buffers/buffers.h
    src/buffers/framebuffers.h
    src/buffers/gfx_output_buffer.h
    src/buffers/zbuffer.h
)

set(SM64_ENGINE_HEADERS
    src/engine/behavior_script.h
    src/engine/geo_layout.h
    src/engine/graph_node.h
    src/engine/level_script.h
    src/engine/math_util.h
    src/engine/surface_collision.h
    src/engine/surface_load.h
)

set(SM64_GAME_HEADERS
    src/game/area.h
    src/game/behavior_actions.h
    src/game/camera.h
    src/game/debug.h
    src/game/debug_course.h
    src/game/decompress.h
    src/game/envfx_bubbles.h
    src/game/envfx_snow.h
    src/game/game_init.h
    src/game/geo_misc.h
    src/game/hud.h
    src/game/ingame_menu.h
    src/game/interaction.h
    src/game/level_geo.h
    src/game/level_update.h
    src/game/macro_special_objects.h
    src/game/main.h
    src/game/mario.h
    src/game/mario_actions_airborne.h
    src/game/mario_actions_automatic.h
    src/game/mario_actions_cutscene.h
    src/game/mario_actions_moving.h
    src/game/mario_actions_object.h
    src/game/mario_actions_stationary.h
    src/game/mario_actions_submerged.h
    src/game/mario_misc.h
    src/game/mario_step.h
    src/game/memory.h
    src/game/moving_texture.h
    src/game/obj_behaviors.h
    src/game/obj_behaviors_2.h
    src/game/object_collision.h
    src/game/object_helpers.h
    src/game/object_list_processor.h
    src/game/paintings.h
    src/game/platform_displacement.h
    src/game/print.h
    src/game/profiler.h
    src/game/rendering_graph_node.h
    src/game/rumble_init.h
    src/game/save_file.h
    src/game/screen_transition.h
    src/game/segment2.h
    src/game/segment7.h
    src/game/shadow.h
    src/game/skybox.h
    src/game/sound_init.h
    src/game/spawn_object.h
)

set(SM64_GODDARD_HEADERS
    src/goddard/bad_declarations.h
    src/goddard/debug_utils.h
    src/goddard/draw_objects.h
    src/goddard/dynlist_proc.h
    src/goddard/gd_macros.h
    src/goddard/gd_main.h
    src/goddard/gd_math.h
    src/goddard/gd_memory.h
    src/goddard/gd_types.h
    src/goddard/joints.h
    src/goddard/objects.h
    src/goddard/old_menu.h
    src/goddard/particles.h
    src/goddard/renderer.h
    src/goddard/sfx.h
    src/goddard/shape_helper.h
    src/goddard/skin.h
    src/goddard/skin_movement.h
    src/goddard/dynlists/animdata.h
    src/goddard/dynlists/dynlist_macros.h
    src/goddard/dynlists/dynlists.h
)

set(SM64_MENU_HEADERS
    src/menu/debug_level_select.h
    src/menu/file_select.h
    src/menu/intro_geo.h
    src/menu/star_select.h
    src/menu/title_screen.h
)

set(SM64_LEVEL_HEADERS
    levels/course_defines.h
    levels/entry.h
    levels/level_defines.h
    levels/scripts.h
)

set(SM64_ACTOR_HEADERS
    actors/common0.h
    actors/common1.h
    actors/group0.h
    actors/group1.h
    actors/group10.h
    actors/group11.h
    actors/group12.h
    actors/group13.h
    actors/group14.h
    actors/group15.h
    actors/group16.h
    actors/group17.h
    actors/group2.h
    actors/group3.h
    actors/group4.h
    actors/group5.h
    actors/group6.h
    actors/group7.h
    actors/group8.h
    actors/group9.h
)

# specific levels
# Main stages
# Bob-omb Battlefield
set(SM64_LEVEL_BOB_HEADERS
    levels/bob/header.h
)
# Whomp's Fortress
set(SM64_LEVEL_WF_HEADERS
    levels/wf/header.h
)
# Jolly Roger Bay
set(SM64_LEVEL_JRB_HEADERS
    levels/jrb/header.h
)
# Cool, Cool Mountain
set(SM64_LEVEL_CCM_HEADERS
    levels/ccm/header.h
)
# Big Boo's Haunt
set(SM64_LEVEL_BBH_HEADERS
    levels/bbh/header.h
)
# Hazy Maze Cave
set(SM64_LEVEL_HMC_HEADERS
    levels/hmc/header.h
)
# Lethal Lava Land
set(SM64_LEVEL_LLL_HEADERS
    levels/lll/header.h
)
# Shifting Sand Land
set(SM64_LEVEL_SSL_HEADERS
    levels/ssl/header.h
)
# Dire, Dire Docks
set(SM64_LEVEL_DDD_HEADERS
    levels/ddd/header.h
)
# Snowman's Land
set(SM64_LEVEL_SL_HEADERS
    levels/sl/header.h
)
# Wet Dry World
set(SM64_LEVEL_WDW_HEADERS
    levels/wdw/header.h
)
# Tall, Tall Mountain
set(SM64_LEVEL_TTM_HEADERS
    levels/ttm/header.h
)
# Tiny-Huge Island
set(SM64_LEVEL_THI_HEADERS
    levels/thi/header.h
)
# Tick Tock Clock
set(SM64_LEVEL_TTC_HEADERS
    levels/ttc/header.h
)
# Rainbow Ride
set(SM64_LEVEL_RR_HEADERS
    levels/rr/header.h
)

# special stages
# Bowser
# Bowser in the Dark World
set(SM64_LEVEL_BITDW_HEADERS
    levels/bitdw/header.h
)
# Bowser in the Dark World (Boss Area)
set(SM64_LEVEL_BITDW_BA_HEADERS
    levels/bowser_1/header.h
)
# Bowser in the Fire Sea
set(SM64_LEVEL_BITFS_HEADERS
    levels/bitfs/header.h
)
# Bowser in the Fire Sea (Boss Area)
set(SM64_LEVEL_BITFS_BA_HEADERS
    levels/bowser_2/header.h
)
# Bowser in the Sky
set(SM64_LEVEL_BITS_HEADERS
    levels/bits/header.h
)
# Bowser in the Sky (Boss Area)
set(SM64_LEVEL_BITS_BA_HEADERS
    levels/bowser_3/header.h
)

# Power-Ups
# Tower of the Wing Cap
set(SM64_LEVEL_TOTWC_HEADERS
    levels/totwc/header.h
)
# Vanish Cap Under the Moat
set(SM64_LEVEL_VCUTM_HEADERS
    levels/vcutm/header.h
)
# Cavern of the Metal Cap
set(SM64_LEVEL_COTMC_HEADERS
    levels/cotmc/header.h
)

# Misc
# Intro
set(SM64_LEVEL_INTRO_HEADERS
    levels/intro/header.h
)
# Ending
set(SM64_LEVEL_ENDING_HEADERS
    levels/ending/header.h
)
# Menu
set(SM64_LEVEL_MENU_HEADERS
    levels/menu/header.h
)
# Castle Courtyard
set(SM64_LEVEL_CASTLE_COURTYARD_HEADERS
    levels/castle_courtyard/header.h
)
# Castle Grounds
set(SM64_LEVEL_CASTLE_GROUNDS_HEADERS
    levels/castle_grounds/header.h
)
# Castle's Inside
set(SM64_LEVEL_CASTLE_INSIDE_HEADERS
    levels/castle_inside/header.h
)
# Secret Aquarium
set(SM64_LEVEL_SA_HEADERS
    levels/sa/header.h
)
# The Princess's Secret Slide
set(SM64_LEVEL_TPSS_HEADERS
    levels/pss/header.h
)
# Wing Mario over the Rainbow
set(SM64_LEVEL_WMOTR_HEADERS
    levels/wmotr/header.h
)

set(SM64_ALL_LEVEL_HEADERS
    # Main stages
    ${SM64_LEVEL_BBH_HEADERS}
    ${SM64_LEVEL_BOB_HEADERS}
    ${SM64_LEVEL_CCM_HEADERS}
    ${SM64_LEVEL_DDD_HEADERS}
    ${SM64_LEVEL_HMC_HEADERS}
    ${SM64_LEVEL_JRB_HEADERS}
    ${SM64_LEVEL_LLL_HEADERS}
    ${SM64_LEVEL_RR_HEADERS}
    ${SM64_LEVEL_SL_HEADERS}
    ${SM64_LEVEL_SSL_HEADERS}
    ${SM64_LEVEL_THI_HEADERS}
    ${SM64_LEVEL_TTC_HEADERS}
    ${SM64_LEVEL_TTM_HEADERS}
    ${SM64_LEVEL_WDW_HEADERS}
    ${SM64_LEVEL_WF_HEADERS}
    # Bowser
    ${SM64_LEVEL_BITDW_HEADERS}
    ${SM64_LEVEL_BITDW_BA_HEADERS}
    ${SM64_LEVEL_BITFS_HEADERS}
    ${SM64_LEVEL_BITFS_BA_HEADERS}
    ${SM64_LEVEL_BITS_HEADERS}
    ${SM64_LEVEL_BITS_BA_HEADERS}
    # Power-Ups
    ${SM64_LEVEL_TOTWC_HEADERS}
    ${SM64_LEVEL_VCUTM_HEADERS}
    ${SM64_LEVEL_COTMC_HEADERS}
    # Misc
    ${SM64_LEVEL_INTRO_HEADERS}
    ${SM64_LEVEL_ENDING_HEADERS}
    ${SM64_LEVEL_MENU_HEADERS}
    ${SM64_LEVEL_CASTLE_COURTYARD_HEADERS}
    ${SM64_LEVEL_CASTLE_GROUNDS_HEADERS}
    ${SM64_LEVEL_CASTLE_INSIDE_HEADERS}
    ${SM64_LEVEL_SA_HEADERS}
    ${SM64_LEVEL_TPSS_HEADERS}
    ${SM64_LEVEL_WMOTR_HEADERS}
)

set(SM64_HEADERS
    ${SM64_AUDIO_HEADERS}
    ${SM64_BUFFERS_HEADERS}
    ${SM64_ENGINE_HEADERS}
    ${SM64_GAME_HEADERS}
    ${SM64_GODDARD_HEADERS}
    ${SM64_MENU_HEADERS}
    ${SM64_LEVEL_HEADERS}
    ${SM64_ACTOR_HEADERS}
    ${SM64_ALL_LEVEL_HEADERS}
)

set(SM64_AUDIO_SOURCES
    src/audio/audio_session_presets_sh.c
    src/audio/data.c
    src/audio/effects.c
    src/audio/external.c
    src/audio/globals_start.c
    src/audio/heap.c
    src/audio/load.c
    src/audio/load_sh.c
    src/audio/playback.c
    src/audio/port_eu.c
    src/audio/port_sh.c
    src/audio/seqplayer.c
    src/audio/shindou_debug_prints.c
    src/audio/synthesis.c
    src/audio/synthesis_sh.c
)

set(SM64_BUFFERS_SOURCES
    src/buffers/buffers.c
    src/buffers/framebuffers.c
    src/buffers/gfx_output_buffer.c
    src/buffers/zbuffer.c
)

set(SM64_ENGINE_SOURCES
    src/engine/behavior_script.c
    src/engine/geo_layout.c
    src/engine/graph_node.c
    src/engine/graph_node_manager.c
    src/engine/level_script.c
    src/engine/math_util.c
    src/engine/stub.c
    src/engine/surface_collision.c
    src/engine/surface_load.c
)

set(SM64_GAME_SOURCES
    src/game/area.c
    src/game/behavior_actions.c
    src/game/camera.c
    src/game/cn_common_syms_1.c
    src/game/cn_common_syms_2.c
    src/game/crash_screen.c
    src/game/debug.c
    src/game/debug_course.c
    src/game/envfx_bubbles.c
    src/game/envfx_snow.c
    src/game/game_init.c
    src/game/geo_misc.c
    src/game/hud.c
    src/game/ingame_menu.c
    src/game/interaction.c
    src/game/level_geo.c
    src/game/level_update.c
    src/game/macro_special_objects.c
    src/game/main.c
    src/game/mario.c
    src/game/mario_actions_airborne.c
    src/game/mario_actions_automatic.c
    src/game/mario_actions_cutscene.c
    src/game/mario_actions_moving.c
    src/game/mario_actions_object.c
    src/game/mario_actions_stationary.c
    src/game/mario_actions_submerged.c
    src/game/mario_misc.c
    src/game/mario_step.c
    src/game/memory.c
    src/game/moving_texture.c
    src/game/obj_behaviors.c
    src/game/obj_behaviors_2.c
    src/game/object_collision.c
    src/game/object_helpers.c
    src/game/object_list_processor.c
    src/game/paintings.c
    src/game/platform_displacement.c
    src/game/print.c
    src/game/profiler.c
    src/game/rendering_graph_node.c
    src/game/rumble_init.c
    src/game/save_file.c
    src/game/screen_transition.c
    src/game/shadow.c
    src/game/skybox.c
    src/game/sound_init.c
    src/game/spawn_object.c
    src/game/spawn_sound.c
)

set(SM64_GODDARD_SOURCES
    src/goddard/debug_utils.c
    src/goddard/draw_objects.c
    src/goddard/dynlist_proc.c
    src/goddard/gd_main.c
    src/goddard/gd_math.c
    src/goddard/gd_memory.c
    src/goddard/joints.c
    src/goddard/objects.c
    src/goddard/old_menu.c
    src/goddard/particles.c
    src/goddard/renderer.c
    src/goddard/sfx.c
    src/goddard/shape_helper.c
    src/goddard/skin.c
    src/goddard/skin_movement.c
    src/goddard/dynlists/anim_group_1.c
    src/goddard/dynlists/anim_group_2.c
    src/goddard/dynlists/anim_mario_eyebrows_1.c
    src/goddard/dynlists/anim_mario_lips_1.c
    src/goddard/dynlists/anim_mario_lips_2.c
    src/goddard/dynlists/anim_mario_mustache_left.c
    src/goddard/dynlists/anim_mario_mustache_right.c
    src/goddard/dynlists/dynlist_mario_face.c
    src/goddard/dynlists/dynlist_mario_master.c
    src/goddard/dynlists/dynlist_test_cube.c
    src/goddard/dynlists/dynlist_unused.c
    src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c
    src/goddard/dynlists/dynlists_mario_eyes.c
)

set(SM64_MENU_SOURCES
    src/menu/file_select.c
    src/menu/intro_geo.c
    src/menu/star_select.c
    src/menu/title_screen.c
)

set(SM64_LEVEL_SOURCES
    levels/entry.c
    levels/scripts.c
)

# specific levels
# Main stages
# Bob-omb Battlefield
set(SM64_LEVEL_BOB_SOURCES
    levels/bob/geo.c
    levels/bob/leveldata.c
    levels/bob/script.c
)
# Whomp's Fortress
set(SM64_LEVEL_WF_SOURCES
    levels/wf/geo.c
    levels/wf/leveldata.c
    levels/wf/script.c
)
# Jolly Roger Bay
set(SM64_LEVEL_JRB_SOURCES
    levels/jrb/geo.c
    levels/jrb/leveldata.c
    levels/jrb/script.c
)
# Cool, Cool Mountain
set(SM64_LEVEL_CCM_SOURCES
    levels/ccm/geo.c
    levels/ccm/leveldata.c
    levels/ccm/script.c
)
# Big Boo's Haunt
set(SM64_LEVEL_BBH_SOURCES
    levels/bbh/geo.c
    levels/bbh/leveldata.c
    levels/bbh/script.c
)
# Hazy Maze Cave
set(SM64_LEVEL_HMC_SOURCES
    levels/hmc/geo.c
    levels/hmc/leveldata.c
    levels/hmc/script.c
)
# Lethal Lava Land
set(SM64_LEVEL_LLL_SOURCES
    levels/lll/geo.c
    levels/lll/leveldata.c
    levels/lll/script.c
)
# Shifting Sand Land
set(SM64_LEVEL_SSL_SOURCES
    levels/ssl/geo.c
    levels/ssl/leveldata.c
    levels/ssl/script.c
)
# Dire, Dire Docks
set(SM64_LEVEL_DDD_SOURCES
    levels/ddd/geo.c
    levels/ddd/leveldata.c
    levels/ddd/script.c
)
# Snowman's Land
set(SM64_LEVEL_SL_SOURCES
    levels/sl/geo.c
    levels/sl/leveldata.c
    levels/sl/script.c
)
# Wet Dry World
set(SM64_LEVEL_WDW_SOURCES
    levels/wdw/geo.c
    levels/wdw/leveldata.c
    levels/wdw/script.c
)
# Tall, Tall Mountain
set(SM64_LEVEL_TTM_SOURCES
    levels/ttm/geo.c
    levels/ttm/leveldata.c
    levels/ttm/script.c
)
# Tiny-Huge Island
set(SM64_LEVEL_THI_SOURCES
    levels/thi/geo.c
    levels/thi/leveldata.c
    levels/thi/script.c
)
# Tick Tock Clock
set(SM64_LEVEL_TTC_SOURCES
    levels/ttc/geo.c
    levels/ttc/leveldata.c
    levels/ttc/script.c
)
# Rainbow Ride
set(SM64_LEVEL_RR_SOURCES
    levels/rr/geo.c
    levels/rr/leveldata.c
    levels/rr/script.c
)

# special stages
# Bowser
# Bowser in the Dark World
set(SM64_LEVEL_BITDW_SOURCES
    levels/bitdw/geo.c
    levels/bitdw/leveldata.c
    levels/bitdw/script.c
)
# Bowser in the Dark World (Boss Area)
set(SM64_LEVEL_BITDW_BA_SOURCES
    levels/bowser_1/geo.c
    levels/bowser_1/leveldata.c
    levels/bowser_1/script.c
)
# Bowser in the Fire Sea
set(SM64_LEVEL_BITFS_SOURCES
    levels/bitfs/geo.c
    levels/bitfs/leveldata.c
    levels/bitfs/script.c
)
# Bowser in the Fire Sea (Boss Area)
set(SM64_LEVEL_BITFS_BA_SOURCES
    levels/bowser_2/geo.c
    levels/bowser_2/leveldata.c
    levels/bowser_2/script.c
)
# Bowser in the Sky
set(SM64_LEVEL_BITS_SOURCES
    levels/bits/geo.c
    levels/bits/leveldata.c
    levels/bits/script.c
)
# Bowser in the Sky (Boss Area)
set(SM64_LEVEL_BITS_BA_SOURCES
    levels/bowser_3/geo.c
    levels/bowser_3/leveldata.c
    levels/bowser_3/script.c
)

# Power-Ups
# Tower of the Wing Cap
set(SM64_LEVEL_TOTWC_SOURCES
    levels/totwc/geo.c
    levels/totwc/leveldata.c
    levels/totwc/script.c
)
# Vanish Cap Under the Moat
set(SM64_LEVEL_VCUTM_SOURCES
    levels/vcutm/geo.c
    levels/vcutm/leveldata.c
    levels/vcutm/script.c
)
# Cavern of the Metal Cap
set(SM64_LEVEL_COTMC_SOURCES
    levels/cotmc/geo.c
    levels/cotmc/leveldata.c
    levels/cotmc/script.c
)

# Misc
# Intro
set(SM64_LEVEL_INTRO_SOURCES
    levels/intro/geo.c
    levels/intro/leveldata.c
    levels/intro/script.c
)
# Ending
set(SM64_LEVEL_ENDING_SOURCES
    levels/ending/geo.c
    levels/ending/leveldata.c
    levels/ending/script.c
)
# Menu
set(SM64_LEVEL_MENU_SOURCES
    levels/menu/geo.c
    levels/menu/leveldata.c
    levels/menu/script.c
)
# Castle Courtyard
set(SM64_LEVEL_CASTLE_COURTYARD_SOURCES
    levels/castle_courtyard/geo.c
    levels/castle_courtyard/leveldata.c
    levels/castle_courtyard/script.c
)
# Castle Grounds
set(SM64_LEVEL_CASTLE_GROUNDS_SOURCES
    levels/castle_grounds/geo.c
    levels/castle_grounds/leveldata.c
    levels/castle_grounds/script.c
)
# Castle's Inside
set(SM64_LEVEL_CASTLE_INSIDE_SOURCES
    levels/castle_inside/geo.c
    levels/castle_inside/leveldata.c
    levels/castle_inside/script.c
)
# Secret Aquarium
set(SM64_LEVEL_SA_SOURCES
    levels/sa/geo.c
    levels/sa/leveldata.c
    levels/sa/script.c
)
# The Princess's Secret Slide
set(SM64_LEVEL_TPSS_SOURCES
    levels/pss/geo.c
    levels/pss/leveldata.c
    levels/pss/script.c
)
# Wing Mario over the Rainbow
set(SM64_LEVEL_WMOTR_SOURCES
    levels/wmotr/geo.c
    levels/wmotr/leveldata.c
    levels/wmotr/script.c
)

set(SM64_ALL_LEVEL_SOURCES
    # Main stages
    ${SM64_LEVEL_BBH_SOURCES}
    ${SM64_LEVEL_BOB_SOURCES}
    ${SM64_LEVEL_CCM_SOURCES}
    ${SM64_LEVEL_DDD_SOURCES}
    ${SM64_LEVEL_HMC_SOURCES}
    ${SM64_LEVEL_JRB_SOURCES}
    ${SM64_LEVEL_LLL_SOURCES}
    ${SM64_LEVEL_RR_SOURCES}
    ${SM64_LEVEL_SL_SOURCES}
    ${SM64_LEVEL_SSL_SOURCES}
    ${SM64_LEVEL_THI_SOURCES}
    ${SM64_LEVEL_TTC_SOURCES}
    ${SM64_LEVEL_TTM_SOURCES}
    ${SM64_LEVEL_WDW_SOURCES}
    ${SM64_LEVEL_WF_SOURCES}
    # Bowser
    ${SM64_LEVEL_BITDW_SOURCES}
    ${SM64_LEVEL_BITDW_BA_SOURCES}
    ${SM64_LEVEL_BITFS_SOURCES}
    ${SM64_LEVEL_BITFS_BA_SOURCES}
    ${SM64_LEVEL_BITS_SOURCES}
    ${SM64_LEVEL_BITS_BA_SOURCES}
    # Power-Ups
    ${SM64_LEVEL_TOTWC_SOURCES}
    ${SM64_LEVEL_VCUTM_SOURCES}
    ${SM64_LEVEL_COTMC_SOURCES}
    # Misc
    ${SM64_LEVEL_INTRO_SOURCES}
    ${SM64_LEVEL_ENDING_SOURCES} # TODO: doesn't compile
    ${SM64_LEVEL_MENU_SOURCES}
    ${SM64_LEVEL_CASTLE_COURTYARD_SOURCES}
    ${SM64_LEVEL_CASTLE_GROUNDS_SOURCES}
    ${SM64_LEVEL_CASTLE_INSIDE_SOURCES}
    ${SM64_LEVEL_SA_SOURCES}
    ${SM64_LEVEL_TPSS_SOURCES}
    ${SM64_LEVEL_WMOTR_SOURCES}
)

set(SM64_ACTOR_SOURCES
    actors/common0.c
    actors/common0_geo.c
    actors/common1.c
    actors/common1_geo.c
    actors/group0.c
    actors/group0_geo.c
    actors/group1.c
    actors/group10.c
    actors/group10_geo.c
    actors/group11.c
    actors/group11_geo.c
    actors/group12.c
    actors/group12_geo.c
    actors/group13.c
    actors/group13_geo.c
    actors/group14.c
    actors/group14_geo.c
    actors/group15.c
    actors/group15_geo.c
    actors/group16.c
    actors/group16_geo.c
    actors/group17.c
    actors/group17_geo.c
    actors/group1_geo.c
    actors/group2.c
    actors/group2_geo.c
    actors/group3.c
    actors/group3_geo.c
    actors/group4.c
    actors/group4_geo.c
    actors/group5.c
    actors/group5_geo.c
    actors/group6.c
    actors/group6_geo.c
    actors/group7.c
    actors/group7_geo.c
    actors/group8.c
    actors/group8_geo.c
    actors/group9.c
    actors/group9_geo.c
)

set(SM64_DATA_SOURCES
    data/behavior_data.c
)

set(SM64_SOUND_SOURCES
    sound/sound_data.c
)

set(SM64_SOURCES
    ${SM64_AUDIO_SOURCES}
    ${SM64_BUFFERS_SOURCES}
    ${SM64_ENGINE_SOURCES}
    ${SM64_GAME_SOURCES}
    ${SM64_GODDARD_SOURCES}
    ${SM64_MENU_SOURCES}
    ${SM64_LEVEL_SOURCES}
    ${SM64_ACTOR_SOURCES}
    ${SM64_DATA_SOURCES}
    ${SM64_SOUND_SOURCES}
    ${SM64_ALL_LEVEL_SOURCES}
)

set(ELF_FILES)

# Create a list to hold the object files
set(OBJECT_FILES)

# Loop through source files to create individual targets
add_custom_target(elf_target)
foreach(SOURCE_FILE ${SM64_SOURCES})
    # Get the filename without extension
    get_filename_component(FILE_NAME ${SOURCE_FILE} NAME_WE)
    get_filename_component(SOURCE_DIR "${SOURCE_FILE}" DIRECTORY)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${SOURCE_DIR}")
    # Set the object file name
    set(OBJECT_FILE ${CURRENT_BINARY_DIR}/${RELATIVE_PATH}/${FILE_NAME}.o)
    set(DEPENDENCY_FILE ${CURRENT_BINARY_DIR}/${RELATIVE_PATH}/${FILE_NAME}.d)

    # Add a custom command to compile the source file
    add_custom_command(
        OUTPUT ${OBJECT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${CURRENT_BINARY_DIR}/${RELATIVE_PATH}/
        COMMAND gcc
            -fsyntax-only -fsigned-char -fno-builtin -nostdinc
            -DTARGET_N64 -D_LANGUAGE_C -std=gnu90
            -Wall -Wextra -Wno-format-security -Wno-main
            -DNON_MATCHING -DAVOID_UB
            -I${CMAKE_SOURCE_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/include/libc/
            -I${CMAKE_SOURCE_DIR}/src/
            -I${CURRENT_BINARY_DIR}/
            -I${CURRENT_BINARY_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
            -DVERSION_JP=1 -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1
            -m32 -MMD -MP -MT ${OBJECT_FILE}
            -MF ${DEPENDENCY_FILE}
            ${CMAKE_SOURCE_DIR}/${SOURCE_FILE}
        COMMAND ${CMAKE_C_COMPILER}
            -c
            -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
            -I${CMAKE_SOURCE_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/include/libc/
            -I${CMAKE_SOURCE_DIR}/src/
            -I${CURRENT_BINARY_DIR}/
            -I${CURRENT_BINARY_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
            -DVERSION_JP=1 -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1
            -mno-shared -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
            -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
            -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
            -ffreestanding -fwrapv -Wall -Wextra -Werror
            -o ${OBJECT_FILE}
            ${CMAKE_SOURCE_DIR}/${SOURCE_FILE}
        DEPENDS ${SOURCE_FILE}
        COMMENT "Compiling ${CMAKE_SOURCE_DIR}/${SOURCE_FILE} -> ${OBJECT_FILE}"
    )

    # Append the object file to the list of object files
    list(APPEND OBJECT_FILES ${OBJECT_FILE})
    string(REPLACE "/" "_" TARGET_NAME "elf_${RELATIVE_PATH}/${FILE_NAME}")
    add_custom_target(${TARGET_NAME} DEPENDS ${OBJECT_FILE} generate_text_strings generate_text_menu_strings generate_level_headers)
    add_dependencies(elf_target ${TARGET_NAME})
endforeach()

add_custom_target(link_elfs)
macro(mio_file INPUT_FILE OUTPUT_FILE TTEXT)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    set(OBJECT_FILE ${OUTPUT_DIR}/${OUTPUT_FILENAME}.o)
    set(DEPENDENCY_FILE ${OUTPUT_DIR}/${OUTPUT_FILENAME}.d)
    set(OUTPUT_ELF ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf)
    set(OUTPUT_BIN ${OUTPUT_DIR}/${OUTPUT_FILENAME}.bin)
    set(OUTPUT_MIO0 ${OUTPUT_DIR}/${OUTPUT_FILENAME}.mio0)

    get_filename_component(INPUT_FILE_EXT "${INPUT_FILE}" EXT)

    # check if the given file is a c file, if it is, compile it
    if(${INPUT_FILE_EXT} STREQUAL ".c")
        add_custom_command(
            OUTPUT ${OBJECT_FILE} ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf.map ${OUTPUT_ELF} ${OUTPUT_MIO0} ${OUTPUT_MIO0}.o
            COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
            # compile
            COMMAND ${CMAKE_C_COMPILER}
                -c ${INPUT_FILE}
                -o ${OBJECT_FILE}
                -MMD -MF ${DEPENDENCY_FILE}
                -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
                -I${CMAKE_SOURCE_DIR}/include
                -I${CMAKE_SOURCE_DIR}/include/libc
                -I${CMAKE_SOURCE_DIR}/src
                -I${CURRENT_BINARY_DIR}
                -I${CURRENT_BINARY_DIR}/bin
                -I${CURRENT_BINARY_DIR}/include
                -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
                -DVERSION_JP=1 -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1
                -mno-shared -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
                -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
                -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
                -ffreestanding -fwrapv -Wall -Wextra -Werror
            # link
            COMMAND ${CMAKE_LINKER}
                    -e 0
                    -Ttext=${TTEXT}
                    -Map ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf.map
                    -o ${OUTPUT_ELF}
                    ${OBJECT_FILE}  # Input object file
            # extract
            COMMAND mips-linux-gnu-objcopy -O binary --only-section=.data ${OUTPUT_ELF} ${OUTPUT_BIN}
            # compress
            COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/mio0 ${OUTPUT_BIN} ${OUTPUT_MIO0}
            # to object file
            COMMAND ${CMAKE_LINKER} -r -b binary ${OUTPUT_MIO0} -o ${OUTPUT_MIO0}.o
            DEPENDS ${INPUT_FILE}
            COMMENT "Compiling and linking to create ELF file: ${INPUT_FILE} -> ${OUTPUT_ELF}"
        )
    else()
        add_custom_command(
            OUTPUT ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf.map ${OUTPUT_ELF} ${OUTPUT_MIO0} ${OUTPUT_MIO0}.o
            COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
            # link
            COMMAND ${CMAKE_LINKER}
                    -e 0
                    -Ttext=${TTEXT}
                    -Map ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf.map
                    -o ${OUTPUT_ELF}
                    ${OBJECT_FILE}  # Input object file
            # extract
            COMMAND mips-linux-gnu-objcopy -O binary --only-section=.data ${OUTPUT_ELF} ${OUTPUT_BIN}
            # compress
            COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/mio0 ${OUTPUT_BIN} ${OUTPUT_MIO0}
            # to object file
            COMMAND ${CMAKE_LINKER} -r -b binary ${OUTPUT_MIO0} -o ${OUTPUT_MIO0}.o
            DEPENDS ${INPUT_FILE}
            COMMENT "Compiling and linking to create ELF file: ${INPUT_FILE} -> ${OUTPUT_ELF}"
        )
    endif()

    list(APPEND ELF_FILES ${OUTPUT_ELF})

    # Create a custom target to link the ELF file
    string(REPLACE "/" "_" TARGET_NAME "mio0${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    add_custom_target(${TARGET_NAME} ALL DEPENDS ${OUTPUT_MIO0}.o)
    add_dependencies(${TARGET_NAME} mio0 elf_target)
    add_dependencies(link_elfs ${TARGET_NAME})
endmacro()

macro(mio_leveldata INPUT_FILE OUTPUT_FILE SYMBOLS_ELF)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}" "" RELATIVE_PATH "${OUTPUT_DIR}")

    set(OBJECT_FILE ${OUTPUT_DIR}/${OUTPUT_FILENAME}.o)
    set(DEPENDENCY_FILE ${OUTPUT_DIR}/${OUTPUT_FILENAME}.d)
    set(OUTPUT_ELF ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf)
    set(OUTPUT_BIN ${OUTPUT_DIR}/${OUTPUT_FILENAME}.bin)
    set(OUTPUT_MIO0 ${OUTPUT_DIR}/${OUTPUT_FILENAME}.mio0)

    add_custom_command(
        OUTPUT ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf.map ${OUTPUT_ELF} ${OUTPUT_BIN} ${OUTPUT_MIO0} ${OUTPUT_MIO0}.o
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        # link
        COMMAND ${CMAKE_LINKER}
                -e 0
                -Ttext=0x07000000 # TODO: make dependent of source file
                -Map ${OUTPUT_DIR}/${OUTPUT_FILENAME}.elf.map
                --just-symbols=${SYMBOLS_ELF}
                -o ${OUTPUT_ELF}
                ${OBJECT_FILE}  # Input object file
        # extract
        COMMAND mips-linux-gnu-objcopy -O binary --only-section=.data ${OUTPUT_ELF} ${OUTPUT_BIN}
        # compress
        COMMAND ${CMAKE_SOURCE_DIR}/tools/sm64tools/mio0 ${OUTPUT_BIN} ${OUTPUT_MIO0}
        # to object file
        COMMAND ${CMAKE_LINKER} -r -b binary ${OUTPUT_MIO0} -o ${OUTPUT_MIO0}.o
        DEPENDS ${OBJECT_FILE}
        COMMENT "Linking to create ELF file: ${INPUT_FILE} -> ${OUTPUT_ELF}"
    )

    list(APPEND ELF_FILES ${OUTPUT_ELF})

    # Create a custom target to link the ELF file
    #message(STATUS "mio0${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    string(REPLACE "/" "_" TARGET_NAME "mio0${RELATIVE_PATH}/${OUTPUT_FILENAME}")
    #message(FATAL_ERROR "${TARGET_NAME}")
    add_custom_target(${TARGET_NAME} ALL DEPENDS ${OUTPUT_MIO0}.o)
    #add_dependencies(${OUTPUT_FILENAME} mio0 convert_textures) # TODO: slow
    add_dependencies(${TARGET_NAME} mio0 elf_target)
    add_dependencies(link_elfs ${TARGET_NAME})
endmacro()

# bin/*.c ---------------------------------------------------------------------
file(GLOB_RECURSE BIN_SOURCE_FILES "${CMAKE_SOURCE_DIR}/bin/*.c")

set(FILTERED_SOURCE_FILES)
# Regex pattern to match files to be removed
set(REMOVE_PATTERN "translation_(de|en|fr)\\.c$")

# Iterate over each file and add it to the new list if it doesn't match the pattern
foreach(file IN LISTS BIN_SOURCE_FILES)
    if(NOT file MATCHES ${REMOVE_PATTERN})
        list(APPEND FILTERED_SOURCE_FILES ${file})
    endif()
endforeach()
# TODO: add translations to eu ROM

foreach(SOURCE_FILE ${FILTERED_SOURCE_FILES})
    get_filename_component(OUTPUT_FILENAME "${SOURCE_FILE}" NAME_WLE)

    set(TTEXT "0x09000000")
    string(REGEX MATCH ".*/segment2.c" IS_SEGMENT2 ${SOURCE_FILE})
    if(IS_SEGMENT2)
        set(TTEXT "0x02000000")
    else()
        string(REGEX MATCH ".*/debug_level_select.c" IS_DEBUG_LEVEL_SELECT ${SOURCE_FILE})
        if(IS_DEBUG_LEVEL_SELECT)
            set(TTEXT "0x07000000")
        else()
            string(REGEX MATCH ".*/effect.c" IS_EFFECT ${SOURCE_FILE})
            if(IS_EFFECT)
                set(TTEXT "0x0B000000")
            else()
                string(REGEX MATCH ".*/title_screen_bg.c" IS_TITLE_SCREEN_BG ${SOURCE_FILE})
                if(IS_TITLE_SCREEN_BG)
                    set(TTEXT "0x0A000000")
                endif()
            endif()
        endif()
    endif()

    mio_file(${SOURCE_FILE} ${CURRENT_BINARY_DIR}/bin/${OUTPUT_FILENAME} ${TTEXT})
endforeach()

# build/[eu/jp/sh/us]/actors/*.o ----------------------------------------------
set(ACTORS_OBJECT_FILES_TO_ELF_FILES
    "${CURRENT_BINARY_DIR}/actors/common0.o#0x08000000"
    "${CURRENT_BINARY_DIR}/actors/common1.o#0x03000000"
    "${CURRENT_BINARY_DIR}/actors/group0.o#0x04000000"
    "${CURRENT_BINARY_DIR}/actors/group1.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group2.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group3.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group4.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group5.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group6.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group7.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group8.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group9.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group10.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group11.o#0x05000000"
    "${CURRENT_BINARY_DIR}/actors/group12.o#0x06000000"
    "${CURRENT_BINARY_DIR}/actors/group13.o#0x06000000"
    "${CURRENT_BINARY_DIR}/actors/group14.o#0x06000000"
    "${CURRENT_BINARY_DIR}/actors/group15.o#0x06000000"
    "${CURRENT_BINARY_DIR}/actors/group16.o#0x06000000"
    "${CURRENT_BINARY_DIR}/actors/group17.o#0x06000000"
)

foreach(OBJECT_TO_ELF_FILE ${ACTORS_OBJECT_FILES_TO_ELF_FILES})
    string(REGEX MATCHALL "[^#]+" OBJECT_TTEXT_PAIR "${OBJECT_TO_ELF_FILE}")
    list(GET OBJECT_TTEXT_PAIR 0 OBJECT_FILE)
    list(GET OBJECT_TTEXT_PAIR 1 TTEXT)
    get_filename_component(OUTPUT_DIR "${OBJECT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OBJECT_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/build/${ROM_VERSION}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    mio_file(${OBJECT_FILE} "${CURRENT_BINARY_DIR}/${RELATIVE_PATH}/${OUTPUT_FILENAME}.elf" ${TTEXT})
endforeach()

# build/[eu/jp/sh/us]/levels/*/leveldata.o ----------------------------------------------
set(LEVELDATA_OBJECT_FILES_TO_ELF_FILES
    "${CURRENT_BINARY_DIR}/levels/bbh/leveldata.o#${CURRENT_BINARY_DIR}/bin/spooky.elf"
    "${CURRENT_BINARY_DIR}/levels/bitdw/leveldata.o#${CURRENT_BINARY_DIR}/bin/sky.elf"
    "${CURRENT_BINARY_DIR}/levels/bitfs/leveldata.o#${CURRENT_BINARY_DIR}/bin/sky.elf"
    "${CURRENT_BINARY_DIR}/levels/bits/leveldata.o#${CURRENT_BINARY_DIR}/bin/sky.elf"
    "${CURRENT_BINARY_DIR}/levels/bob/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/bowser_1/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/bowser_2/leveldata.o#${CURRENT_BINARY_DIR}/bin/fire.elf"
    "${CURRENT_BINARY_DIR}/levels/bowser_3/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/castle_courtyard/leveldata.o#${CURRENT_BINARY_DIR}/bin/outside.elf"
    "${CURRENT_BINARY_DIR}/levels/castle_grounds/leveldata.o#${CURRENT_BINARY_DIR}/bin/outside.elf"
    "${CURRENT_BINARY_DIR}/levels/castle_inside/leveldata.o#${CURRENT_BINARY_DIR}/bin/inside.elf"
    "${CURRENT_BINARY_DIR}/levels/ccm/leveldata.o#${CURRENT_BINARY_DIR}/bin/snow.elf"
    "${CURRENT_BINARY_DIR}/levels/cotmc/leveldata.o#${CURRENT_BINARY_DIR}/bin/cave.elf"
    "${CURRENT_BINARY_DIR}/levels/ddd/leveldata.o#${CURRENT_BINARY_DIR}/bin/water.elf"
    "${CURRENT_BINARY_DIR}/levels/ending/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/hmc/leveldata.o#${CURRENT_BINARY_DIR}/bin/cave.elf"
    "${CURRENT_BINARY_DIR}/levels/intro/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/jrb/leveldata.o#${CURRENT_BINARY_DIR}/bin/water.elf"
    "${CURRENT_BINARY_DIR}/levels/lll/leveldata.o#${CURRENT_BINARY_DIR}/bin/fire.elf"
    "${CURRENT_BINARY_DIR}/levels/menu/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/pss/leveldata.o#${CURRENT_BINARY_DIR}/bin/mountain.elf"
    "${CURRENT_BINARY_DIR}/levels/rr/leveldata.o#${CURRENT_BINARY_DIR}/bin/sky.elf"
    "${CURRENT_BINARY_DIR}/levels/sa/leveldata.o#${CURRENT_BINARY_DIR}/bin/inside.elf"
    "${CURRENT_BINARY_DIR}/levels/sl/leveldata.o#${CURRENT_BINARY_DIR}/bin/snow.elf"
    "${CURRENT_BINARY_DIR}/levels/ssl/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
    "${CURRENT_BINARY_DIR}/levels/thi/leveldata.o#${CURRENT_BINARY_DIR}/bin/grass.elf"
    "${CURRENT_BINARY_DIR}/levels/totwc/leveldata.o#${CURRENT_BINARY_DIR}/bin/sky.elf"
    "${CURRENT_BINARY_DIR}/levels/ttc/leveldata.o#${CURRENT_BINARY_DIR}/bin/machine.elf"
    "${CURRENT_BINARY_DIR}/levels/ttm/leveldata.o#${CURRENT_BINARY_DIR}/bin/mountain.elf"
    "${CURRENT_BINARY_DIR}/levels/vcutm/leveldata.o#${CURRENT_BINARY_DIR}/bin/outside.elf"
    "${CURRENT_BINARY_DIR}/levels/wdw/leveldata.o#${CURRENT_BINARY_DIR}/bin/grass.elf"
    "${CURRENT_BINARY_DIR}/levels/wf/leveldata.o#${CURRENT_BINARY_DIR}/bin/grass.elf"
    "${CURRENT_BINARY_DIR}/levels/wmotr/leveldata.o#${CURRENT_BINARY_DIR}/bin/generic.elf"
)

foreach(OBJECT_TO_ELF_FILE ${LEVELDATA_OBJECT_FILES_TO_ELF_FILES})
    string(REGEX MATCHALL "[^#]+" OBJECT_ELF_PAIR "${OBJECT_TO_ELF_FILE}")
    list(GET OBJECT_ELF_PAIR 0 OBJECT_FILE)
    list(GET OBJECT_ELF_PAIR 1 ELF_FILE)
    get_filename_component(OUTPUT_DIR "${OBJECT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OBJECT_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/build/${ROM_VERSION}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    mio_leveldata(${OBJECT_FILE} "${CURRENT_BINARY_DIR}/${RELATIVE_PATH}/${OUTPUT_FILENAME}.elf" ${ELF_FILE})
endforeach()

# build/[eu/jp/sh/us]/bin/*_skybox.c ----------------------------------------------
# these are generated by converting the skybox textures
set(SKYBOX_SOURCE_FILES_TO_ELF_FILES
    "${CURRENT_BINARY_DIR}/bin/wdw_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/bbh_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/bidw_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/bitfs_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/bits_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/ccm_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/cloud_floor_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/clouds_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/ssl_skybox.c#0x0A000000"
    "${CURRENT_BINARY_DIR}/bin/water_skybox.c#0x0A000000"
)

foreach(SOURCE_FILE_TO_ELF ${SKYBOX_SOURCE_FILES_TO_ELF_FILES})
    string(REGEX MATCHALL "[^#]+" SOURCE_TTEXT_PAIR "${SOURCE_FILE_TO_ELF}")
    list(GET SOURCE_TTEXT_PAIR 0 SOURCE_FILE)
    list(GET SOURCE_TTEXT_PAIR 1 TTEXT)
    get_filename_component(OUTPUT_DIR "${SOURCE_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${SOURCE_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/build/${ROM_VERSION}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    mio_file(${SOURCE_FILE} "${CURRENT_BINARY_DIR}/${RELATIVE_PATH}/${OUTPUT_FILENAME}.elf" ${TTEXT})
endforeach()

# add executable --------------------------------------------------------------
set(SM64_ELF ${CURRENT_BINARY_DIR}/sm64.${ROM_VERSION}.elf)
add_custom_command(
    OUTPUT ${SM64_ELF}
    COMMAND ${CMAKE_LINKER}
    -L${CURRENT_BINARY_DIR}
    -L${CMAKE_SOURCE_DIR}
    -T ${CMAKE_SOURCE_DIR}/undefined_syms.txt
    -T ${CURRENT_BINARY_DIR}/sm64.ld
    -Map ${CURRENT_BINARY_DIR}/sm64.jp.map
    --no-check-sections
    -R ${ELF_FILES}
    -o ${SM64_ELF}
    ${OBJECT_FILES}
    -lultra -lgoddard -lgcc
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${SOURCE_FILE}
    COMMENT "Building sm64.${ROM_VERSION}.elf"
)
add_custom_target(sm64_elf ALL DEPENDS ${SM64_ELF})
#add_executable(sm64 ${OBJECT_FILES})
#set_target_properties(sm64 PROPERTIES LINKER_LANGUAGE C)
##add_executable(sm64 ${SM64_HEADERS} ${SM64_SOURCES})
#add_dependencies(sm64 elf_target)

# configure targets ------------------------------------------------------------
#target_include_directories(sm64
#    PRIVATE
#    ${CMAKE_SOURCE_DIR}/include/
#    ${CMAKE_SOURCE_DIR}/include/libc/
#    ${CMAKE_SOURCE_DIR}/src/
#    ${CURRENT_BINARY_DIR}/
#    ${CURRENT_BINARY_DIR}/include/
#    ${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
#)

# link targets -----------------------------------------------------------------
#target_link_libraries(sm64
#    PRIVATE
#)

#get_target_property(COMPILE_OPTIONS sm64 COMPILE_OPTIONS)
#if(COMPILE_OPTIONS)
#    string(JOIN " " COMPILE_OPTIONS_STR ${COMPILE_OPTIONS})
#else()
#    set(COMPILE_OPTIONS_STR "")
#endif()
#message(STATUS "Compile options: ${COMPILE_OPTIONS_STR}")
#
#get_directory_property(GLOBAL_COMPILE_OPTIONS DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_OPTIONS)
#if(GLOBAL_COMPILE_OPTIONS)
#    string(JOIN " " GLOBAL_COMPILE_OPTIONS_STR ${GLOBAL_COMPILE_OPTIONS})
#else()
#    set(GLOBAL_COMPILE_OPTIONS_STR "")
#endif()
#message(STATUS "Global compile options: ${GLOBAL_COMPILE_OPTIONS_STR}")
#
#get_directory_property(GLOBAL_COMPILE_DEFINITIONS DIRECTORY ${CMAKE_SOURCE_DIR} COMPILE_DEFINITIONS)
#if(GLOBAL_COMPILE_DEFINITIONS)
#    string(JOIN " " GLOBAL_COMPILE_DEFINITIONS_STR ${GLOBAL_COMPILE_DEFINITIONS})
#else()
#    set(GLOBAL_COMPILE_DEFINITIONS_STR "")
#endif()
#message(STATUS "Global compile definitions: ${GLOBAL_COMPILE_DEFINITIONS_STR}")
#
#get_target_property(LINK_OPTIONS sm64 LINK_OPTIONS)
#if(LINK_OPTIONS)
#    string(JOIN " " LINK_OPTIONS_STR ${LINK_OPTIONS})
#else()
#    set(LINK_OPTIONS_STR "")
#endif()
#message(STATUS "Linker options: ${LINK_OPTIONS_STR}")
