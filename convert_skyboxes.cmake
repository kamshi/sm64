cmake_minimum_required(VERSION 3.10)

set(CONVERTED_SKYBOXES)
macro(convert_skybox INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/skyconv
        --type sky
        --split ${INPUT_FILE}
        ${OUTPUT_DIR}
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting skybox: ${INPUT_FILE} -> ${OUTPUT_FILE}"
    )

    list(APPEND CONVERTED_SKYBOXES ${OUTPUT_FILE})
endmacro()

set(SKYBOX_DIRECTORIES
    textures/skyboxes
)

foreach(SKYBOX_DIRECTORY ${SKYBOX_DIRECTORIES})
    file(GLOB PNG_FILES "${SKYBOX_DIRECTORY}/*.png")
    foreach(PNG_FILE ${PNG_FILES})
        get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
        get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
        string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
        convert_skybox(${PNG_FILE} "${ABSOLUTE_BUILD_DIR}/bin/${OUTPUT_FILENAME}_skybox")
    endforeach()
endforeach()
add_custom_target(convert_skyboxes DEPENDS ${CONVERTED_SKYBOXES})
