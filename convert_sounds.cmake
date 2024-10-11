cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/sound/sound_data.ctl.inc.c
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/sound/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
        ${RELATIVE_BUILD_DIR}/sound/samples/
        sound/sound_banks/
        ${RELATIVE_BUILD_DIR}/sound/sound_data.ctl
        ${RELATIVE_BUILD_DIR}/sound/ctl_header
        ${RELATIVE_BUILD_DIR}/sound/sound_data.tbl
        ${RELATIVE_BUILD_DIR}/sound/tbl_header
        -D${ROM_VERSION_STRING}=1
        -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 # TODO
        "$(cat ${RELATIVE_BUILD_DIR}/endian-and-bitwidth)"
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${RELATIVE_BUILD_DIR}/sound/sound_data.ctl > ${RELATIVE_BUILD_DIR}/sound/sound_data.ctl.inc.c
    COMMAND echo >> ${RELATIVE_BUILD_DIR}/sound/sound_data.ctl.inc.c
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${RELATIVE_BUILD_DIR}/sound/sound_data.tbl > ${RELATIVE_BUILD_DIR}/sound/sound_data.tbl.inc.c
    COMMAND echo >> ${RELATIVE_BUILD_DIR}/sound/sound_data.tbl.inc.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
    COMMENT "Converting sounds"
)
add_custom_target(convert_sounds ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/sound/sound_data.ctl.inc.c)
