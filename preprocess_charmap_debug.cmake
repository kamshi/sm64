cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/charmap.debug.txt
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
            -MMD -MP -MT ${ABSOLUTE_BUILD_DIR}/charmap.debug.txt
            -MF ${ABSOLUTE_BUILD_DIR}/charmap.debug.txt.d
            -o ${ABSOLUTE_BUILD_DIR}/charmap.debug.txt
            ${CMAKE_SOURCE_DIR}/${CHARMAP}
    DEPENDS ${CMAKE_SOURCE_DIR}/${CHARMAP}
    COMMENT "Preprocessing charmap: charmap.debug.txt"
)
add_custom_target(preprocess_charmap_debug ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/charmap.debug.txt)
