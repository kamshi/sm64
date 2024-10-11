cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/include/text_strings.h
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/include/
    COMMAND ${CMAKE_SOURCE_DIR}/tools/textconv ${ABSOLUTE_BUILD_DIR}/${CHARMAP} ${CMAKE_SOURCE_DIR}/include/text_strings.h.in ${ABSOLUTE_BUILD_DIR}/include/text_strings.h
    DEPENDS ${ABSOLUTE_BUILD_DIR}/${CHARMAP} ${CMAKE_SOURCE_DIR}/include/text_strings.h.in textconv
    COMMENT "Generating text_strings.h from textconv..."
)
add_custom_target(generate_text_strings ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/include/text_strings.h)
add_dependencies(generate_text_strings textconv)
