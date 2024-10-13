cmake_minimum_required(VERSION 3.10)

set(ENCODED_SOUNDS)
macro(encode_sound INPUT_FILE)
    get_filename_component(OUTPUT_DIR "${INPUT_FILE}" DIRECTORY)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    get_filename_component(OUTPUT_FILENAME "${INPUT_FILE}" NAME_WLE)
    string(REPLACE "#" "_sharp_" MODIFIED_FILENAME "${OUTPUT_FILENAME}")

    if(${MODIFIED_FILENAME} STREQUAL ${OUTPUT_FILENAME})
        add_custom_command(
            OUTPUT ${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            COMMAND ${CMAKE_COMMAND} -E make_directory ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/
            COMMAND ${CMAKE_SOURCE_DIR}/tools/aiff_extract_codebook ${INPUT_FILE} >${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.table
            COMMAND ${CMAKE_SOURCE_DIR}/tools/vadpcm_enc -c ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.table ${INPUT_FILE} ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            DEPENDS aiff_extract_codebook vadpcm_enc
            COMMENT "Encoding sound ${INPUT_FILE} -> ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc"
        )
    else()
        # hack: cmake output can't contain #, so we generate an additional file not containing the #
        add_custom_command(
            OUTPUT ${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            COMMAND ${CMAKE_COMMAND} -E make_directory ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/
            COMMAND ${CMAKE_SOURCE_DIR}/tools/aiff_extract_codebook ${INPUT_FILE} >${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.table
            COMMAND ${CMAKE_SOURCE_DIR}/tools/vadpcm_enc -c ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.table ${INPUT_FILE} ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc
            COMMAND ${CMAKE_COMMAND} -E copy "${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.table" "${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${OUTPUT_FILENAME}.table"
            COMMAND ${CMAKE_COMMAND} -E copy "${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc" "${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${OUTPUT_FILENAME}.aifc"
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            DEPENDS aiff_extract_codebook vadpcm_enc
            COMMENT "Encoding sound ${INPUT_FILE} -> ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc"
        )
    endif()

    list(APPEND ENCODED_SOUNDS "${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${MODIFIED_FILENAME}.aifc")
endmacro()

include(sound_aiffs_${ROM_VERSION}.cmake)
foreach(SOUND_FILE ${SOUND_AIFFS})
    get_filename_component(OUTPUT_DIR "${SOUND_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${SOUND_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    encode_sound(${OUTPUT_DIR}/${OUTPUT_FILENAME}.aiff)
endforeach()

add_custom_target(encode_sounds DEPENDS ${ENCODED_SOUNDS})
add_dependencies(encode_sounds extract_assets)
