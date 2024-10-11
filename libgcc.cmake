cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/libgcc.a
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}
    # link
    COMMAND ${CMAKE_AR} rcs -o ${ABSOLUTE_BUILD_DIR}/libgcc.a
    COMMENT "Linking libgcc"
)

add_custom_target(libgcc ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/libgcc.a)
