cmake_minimum_required(VERSION 3.10)

set(LEVEL_RULES_MK levels/level_rules.mk)
add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/level_rules.mk
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${ABSOLUTE_BUILD_DIR}
            -I${ABSOLUTE_BUILD_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -o ${ABSOLUTE_BUILD_DIR}/level_rules.mk
            ${CMAKE_SOURCE_DIR}/${LEVEL_RULES_MK}
    DEPENDS ${CMAKE_SOURCE_DIR}/${LEVEL_RULES_MK}
    COMMENT "Preprocessing level rules: ${LEVEL_RULES_MK}"
)
add_custom_target(preprocess_level_rules ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/level_rules.mk)
