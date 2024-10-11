cmake_minimum_required(VERSION 3.10)

set(LEVEL_RULES_MK levels/level_rules.mk)
add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/sm64.ld
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${RELATIVE_BUILD_DIR}
            -I${RELATIVE_BUILD_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -DBUILD_DIR=build/${ROM_VERSION}
            -MMD -MP -MT ${RELATIVE_BUILD_DIR}/sm64.ld
            -MF ${RELATIVE_BUILD_DIR}/sm64.ld.d
            -o ${RELATIVE_BUILD_DIR}/sm64.ld
            ${CMAKE_SOURCE_DIR}/sm64.ld
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${CMAKE_SOURCE_DIR}/${LEVEL_RULES_MK}
    COMMENT "Preprocessing sm64.ld"
)
add_custom_target(preprocess_sm64.ld ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/sm64.ld)
