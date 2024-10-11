cmake_minimum_required(VERSION 3.10)

set(CHARMAP charmap.txt)
add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/${CHARMAP}
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/
    COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
            -I${CMAKE_SOURCE_DIR}/include
            -I${ABSOLUTE_BUILD_DIR}
            -I${ABSOLUTE_BUILD_DIR}/include
            -I${CMAKE_SOURCE_DIR}/src
            -I${CMAKE_SOURCE_DIR}
            -I${CMAKE_SOURCE_DIR}/include/libc
            ${SM64_COMPILE_DEFINITIONS}
            -DBUILD_DIR=${ABSOLUTE_BUILD_DIR}
            -MMD -MP -MT ${ABSOLUTE_BUILD_DIR}/${CHARMAP}
            -MF ${ABSOLUTE_BUILD_DIR}/${CHARMAP}.d
            -o ${ABSOLUTE_BUILD_DIR}/${CHARMAP}
            ${CMAKE_SOURCE_DIR}/${CHARMAP}
    DEPENDS ${CMAKE_SOURCE_DIR}/${CHARMAP}
    COMMENT "Preprocessing charmap: ${CHARMAP}"
)
add_custom_target(preprocess_charmap ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/${CHARMAP})
