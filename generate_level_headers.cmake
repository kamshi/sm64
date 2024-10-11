cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/level_headers.h.temp
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${ABSOLUTE_BUILD_DIR}
            -I${ABSOLUTE_BUILD_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            ${CMAKE_SOURCE_DIR}/levels/level_headers.h.in > ${ABSOLUTE_BUILD_DIR}/level_headers.h.temp
    DEPENDS ${CMAKE_SOURCE_DIR}/levels/level_headers.h.in
    COMMENT "Preprocessing level headers: levels/level_headers.h.in"
)
add_custom_target(preprocess_level_headers_temp ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/level_headers.h.temp)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/include/level_headers.h
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/include/
    COMMAND $<TARGET_FILE:generate_level_header> ${ABSOLUTE_BUILD_DIR}/level_headers.h.temp ${ABSOLUTE_BUILD_DIR}/include/level_headers.h
    DEPENDS ${ABSOLUTE_BUILD_DIR}/level_headers.h.temp generate_level_header
    COMMENT "Generating level_headers.h from ${TEMP_FILE} using generate_level_header..."
)
add_custom_target(generate_level_headers ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/include/level_headers.h)
