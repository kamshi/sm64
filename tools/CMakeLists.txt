# cmake configuration ---------------------------------------------------------
cmake_minimum_required(VERSION 3.10)

# define project --------------------------------------------------------------
project(tools LANGUAGES C CXX)

# set to non-cross compiler
set(CMAKE_C_COMPILER "/usr/bin/clang")
set(CMAKE_CXX_COMPILER "/usr/bin/clang++")

set(ARMIPS_SOURCES
    armips.cpp
)

set(TEXTCONV_HEADERS
    hashtable.h
    utf8.h
)

set(TEXTCONV_SOURCES
    hashtable.c
    textconv.c
    utf8.c
)

set(SKYCONV_HEADERS
    sm64tools/n64graphics.h
    sm64tools/utils.h
)

set(SKYCONV_SOURCES
    skyconv.c
    sm64tools/n64graphics.c
    sm64tools/utils.c
)

set(GENERATE_LEVEL_HEADER_SOURCES
    generate_level_header.cpp
)

set(AIFF_EXTRACT_CODEBOOK_SOURCES
    aiff_extract_codebook.c
)

set(VADPCM_ENC_SOURCES
    sdk-tools/adpcm/vadpcm_enc.c
    sdk-tools/adpcm/vpredictor.c
    sdk-tools/adpcm/quant.c
    sdk-tools/adpcm/util.c
    sdk-tools/adpcm/vencode.c
)

# add executables -------------------------------------------------------------
add_executable(armips ${ARMIPS_SOURCES})
add_executable(textconv ${TEXTCONV_HEADERS} ${TEXTCONV_SOURCES})
add_executable(skyconv ${SKYCONV_HEADERS} ${SKYCONV_SOURCES})
add_executable(generate_level_header ${GENERATE_LEVEL_HEADER_SOURCES})
add_executable(aiff_extract_codebook ${AIFF_EXTRACT_CODEBOOK_SOURCES})
add_executable(vadpcm_enc ${VADPCM_ENC_SOURCES})

# configure targets -----------------------------------------------------------
target_include_directories(armips
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
)

target_compile_options(armips PRIVATE -std=c++11 -fno-exceptions -fno-rtti -pipe)
target_compile_definitions(armips PRIVATE -DMIO0_STANDALONE)
set_target_properties(armips PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

target_include_directories(textconv
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
)

target_compile_options(textconv PRIVATE -Wall -Wextra -Wno-unused-parameter -pedantic -O2 -s)
target_compile_definitions(textconv PRIVATE -DMIO0_STANDALONE)
set_target_properties(textconv PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

target_include_directories(skyconv
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/sm64tools # TODO: fix includes instead of adding this path
)

target_compile_options(skyconv PRIVATE -Wall -Wextra -Wno-unused-parameter -pedantic -O2 -s)
set_target_properties(skyconv PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_options(generate_level_header PRIVATE -Wall -Wextra -pedantic -O2)
set_target_properties(generate_level_header PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_options(aiff_extract_codebook PRIVATE -Wall -Wextra -pedantic -O2)
set_target_properties(aiff_extract_codebook PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

target_compile_options(vadpcm_enc PRIVATE -Wall -Wextra -pedantic -O2)
set_target_properties(vadpcm_enc PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# link targets -----------------------------------------------------------------
target_link_libraries(armips
    PRIVATE
    pthread
)

target_link_libraries(textconv
    PRIVATE
)

target_link_libraries(skyconv
    PRIVATE
)

target_link_libraries(generate_level_header
    PRIVATE
)

target_link_libraries(aiff_extract_codebook
    PRIVATE
)

target_link_libraries(vadpcm_enc
    PRIVATE
)

# add subdirectories ----------------------------------------------------------
add_subdirectory(sm64tools)

add_custom_target(tools ALL DEPENDS textconv sm64tools skyconv aiff_extract_codebook vadpcm_enc)
