# cmake configuration ---------------------------------------------------------
cmake_minimum_required(VERSION 3.10)

# define project --------------------------------------------------------------
project(sm64tools C)

# set to non-cross compiler
set(CMAKE_C_COMPILER "/usr/bin/gcc")
set(CMAKE_CXX_COMPILER "/usr/bin/g++")

set(MIO0_HEADERS
    libmio0.h
)

set(MIO0_SOURCES
    libmio0.c
)

set(N64CKSUM_HEADERS
    n64cksum.h
    utils.h
)

set(N64CKSUM_SOURCES
    n64cksum.c
    utils.c
)

set(N64GRAPHICS_HEADERS
n64graphics.h
    utils.h
)

set(N64GRAPHICS_SOURCES
    n64graphics.c
    utils.c
)

set(N64GRAPHICS_CI_HEADERS
    n64graphics_ci_dir/n64graphics_ci.h
    n64graphics_ci_dir/exoquant/exoquant.h
    n64graphics_ci_dir/utils.h
)

set(N64GRAPHICS_CI_SOURCES
    n64graphics_ci_dir/n64graphics_ci.c
    n64graphics_ci_dir/exoquant/exoquant.c
    n64graphics_ci_dir/utils.c
)

# add executables -------------------------------------------------------------
add_executable(mio0 ${MIO0_HEADERS} ${MIO0_SOURCES})
add_executable(n64cksum ${N64CKSUM_HEADERS} ${N64CKSUM_SOURCES})
add_executable(n64graphics ${N64GRAPHICS_HEADERS} ${N64GRAPHICS_SOURCES})
add_executable(n64graphics_ci ${N64GRAPHICS_CI_HEADERS} ${N64GRAPHICS_CI_SOURCES})

# configure targets -----------------------------------------------------------
target_include_directories(mio0
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
)
target_include_directories(n64cksum
PRIVATE
${CMAKE_CURRENT_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
)
target_include_directories(n64graphics
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
)
target_include_directories(n64graphics_ci
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
)

target_compile_options(mio0 PRIVATE -Wall -Wextra -Wno-unused-parameter -pedantic -O2 -s)
target_compile_definitions(mio0 PRIVATE -DMIO0_STANDALONE)
set_target_properties(mio0 PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
target_compile_options(n64cksum PRIVATE -Wall -Wextra -Wno-unused-parameter -pedantic -O2 -s)
target_compile_definitions(n64cksum PRIVATE -DN64CKSUM_STANDALONE)
set_target_properties(n64cksum PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
target_compile_options(n64graphics PRIVATE -Wall -Wextra -Wno-unused-parameter -pedantic -O2 -s)
target_compile_definitions(n64graphics PRIVATE -DN64GRAPHICS_STANDALONE)
set_target_properties(n64graphics PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
target_compile_options(n64graphics_ci PRIVATE -Wall -Wextra -Wno-unused-parameter -pedantic -O2 -s)
set_target_properties(n64graphics_ci PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

# link targets -----------------------------------------------------------------
target_link_libraries(mio0
    PRIVATE
)
target_link_libraries(n64cksum
    PRIVATE
)
target_link_libraries(n64graphics
    PRIVATE
)
target_link_libraries(n64graphics_ci
    PRIVATE
    m
)

add_custom_target(sm64tools ALL DEPENDS mio0 n64cksum n64graphics n64graphics_ci)
