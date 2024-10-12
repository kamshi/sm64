cmake_minimum_required(VERSION 3.10)

set(CONVERTED_CAKES)
macro(convert_cake INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND ${CMAKE_SOURCE_DIR}/tools/skyconv
        --type cake
        --split ${INPUT_FILE}
        ${OUTPUT_DIR}
        #DEPENDS ${INPUT_FILE}
        #DEPENDS extract_assets
        COMMENT "Converting cake: ${INPUT_FILE} -> ${OUTPUT_FILE}"
    )

    list(APPEND CONVERTED_CAKES ${OUTPUT_FILE})
endmacro()

include(cake_pngs_${ROM_VERSION}.cmake)
foreach(PNG_FILE ${CAKE_PNGS})
    get_filename_component(OUTPUT_DIR "${PNG_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${PNG_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    convert_cake(${PNG_FILE} "${ABSOLUTE_BUILD_DIR}/levels/ending/${OUTPUT_FILENAME}.inc.c")
endforeach()
add_custom_target(convert_cakes DEPENDS ${CONVERTED_CAKES})
