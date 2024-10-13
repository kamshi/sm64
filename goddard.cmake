cmake_minimum_required(VERSION 3.10)

set(GODDARD_HEADERS
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

# IMPORTANT: the order here matters for the linking stage
set(GODDARD_SOURCES
    src/goddard/old_menu.c
    src/goddard/particles.c
    src/goddard/dynlist_proc.c
    src/goddard/renderer.c
    src/goddard/skin_movement.c
    src/goddard/skin.c
    src/goddard/joints.c
    src/goddard/objects.c
    src/goddard/draw_objects.c
    src/goddard/debug_utils.c
    src/goddard/gd_math.c
    src/goddard/gd_memory.c
    src/goddard/gd_main.c
    src/goddard/sfx.c
    src/goddard/shape_helper.c
    src/goddard/dynlists/dynlist_test_cube.c
    src/goddard/dynlists/dynlists_mario_eyes.c
    src/goddard/dynlists/anim_mario_lips_1.c
    src/goddard/dynlists/dynlist_mario_master.c
    src/goddard/dynlists/anim_mario_eyebrows_1.c
    src/goddard/dynlists/anim_group_2.c
    src/goddard/dynlists/anim_mario_mustache_left.c
    src/goddard/dynlists/dynlist_mario_face.c
    src/goddard/dynlists/anim_mario_lips_2.c
    src/goddard/dynlists/anim_mario_mustache_right.c
    src/goddard/dynlists/dynlist_unused.c
    src/goddard/dynlists/dynlists_mario_eyebrows_mustache.c
    src/goddard/dynlists/anim_group_1.c
)

set(GODDARD_OBJECT_FILES)
foreach(SOURCE_FILE ${GODDARD_SOURCES})
    # Get the filename without extension
    get_filename_component(FILE_NAME ${SOURCE_FILE} NAME_WE)
    get_filename_component(SOURCE_DIR "${SOURCE_FILE}" DIRECTORY)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_SOURCE_FILE "${SOURCE_FILE}")
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${SOURCE_DIR}")
    # Set the object file name
    set(OBJECT_FILE ${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${FILE_NAME}.o)
    set(RELATIVE_OBJECT_FILE ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${FILE_NAME}.o)
    set(DEPENDENCY_FILE ${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${FILE_NAME}.d)

    # Add a custom command to compile the source file
    add_custom_command(
        OUTPUT ${OBJECT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/
        COMMAND gcc
            -fsyntax-only -fsigned-char -fno-builtin -nostdinc
            -DTARGET_N64 -D_LANGUAGE_C -std=gnu90
            -Wall -Wextra -Wno-format-security -Wno-main
            -DNON_MATCHING -DAVOID_UB
            -I${CMAKE_SOURCE_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/include/libc/
            -I${CMAKE_SOURCE_DIR}/src/
            -I${RELATIVE_BUILD_DIR}/
            -I${RELATIVE_BUILD_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
            -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1
            -m32 -MMD -MP -MT ${OBJECT_FILE}
            -MF ${DEPENDENCY_FILE}
            ${CMAKE_SOURCE_DIR}/${SOURCE_FILE}
        COMMAND ${CMAKE_C_COMPILER}
            -c
            -G 0 -O2 -nostdinc -DTARGET_N64 -D_LANGUAGE_C -mips3
            -I${CMAKE_SOURCE_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/include/libc/
            -I${CMAKE_SOURCE_DIR}/src/
            -I${RELATIVE_BUILD_DIR}/
            -I${RELATIVE_BUILD_DIR}/include/
            -I${CMAKE_SOURCE_DIR}/ # TODO: fix includes instead of adding this path
            -D${ROM_VERSION_STRING}=1 -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1
            -mno-shared -march=vr4300 -mfix4300 -mabi=32 -mhard-float -mdivide-breaks
            -fno-stack-protector -fno-common -fno-zero-initialized-in-bss
            -fno-PIC -mno-abicalls -fno-strict-aliasing -fno-inline-functions
            -ffreestanding -fwrapv -Wall -Wextra -Werror
            -o ${OBJECT_FILE}
            ${CMAKE_SOURCE_DIR}/${SOURCE_FILE}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        DEPENDS ${SOURCE_FILE}
        COMMENT "Compiling ${RELATIVE_SOURCE_FILE} -> ${RELATIVE_OBJECT_FILE}"
    )

    # Append the object file to the list of object files
    list(APPEND GODDARD_OBJECT_FILES ${OBJECT_FILE})
endforeach()

set(RELATIVE_GODDARD_OBJECT_FILES)
foreach(OBJECT_FILE ${GODDARD_OBJECT_FILES})
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OBJECT_FILE}")
    list(APPEND RELATIVE_GODDARD_OBJECT_FILES ${RELATIVE_PATH})
endforeach()

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/libgoddard.a
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}
    # link
    COMMAND ${CMAKE_AR}
            rcs -o ${RELATIVE_BUILD_DIR}/libgoddard.a
            ${RELATIVE_GODDARD_OBJECT_FILES}  # Input object file
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${GODDARD_OBJECT_FILES}
    COMMENT "Compiling and linking to create libgoddard"
)

add_custom_target(goddard ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/libgoddard.a)
add_dependencies(goddard convert_textures)
