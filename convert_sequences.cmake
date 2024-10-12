cmake_minimum_required(VERSION 3.10)

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/sound/bank_sets.inc.c
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}/sound/
    COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
        --sequences
        ${ABSOLUTE_BUILD_DIR}/sound/sequences.bin
        ${ABSOLUTE_BUILD_DIR}/sound/sequences_header
        ${ABSOLUTE_BUILD_DIR}/sound/bank_sets sound/sound_banks/
        ${CMAKE_SOURCE_DIR}/sound/sequences.json
        ${ABSOLUTE_BUILD_DIR}/sound/sequences/00_sound_player.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/1D_event_peach_message.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/1A_cutscene_credits.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/0D_menu_star_select.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/03_level_grass.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/02_menu_title_screen.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/11_level_koopa_road.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/14_event_race.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/1B_event_solve_puzzle.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/05_level_water.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/12_event_high_score.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/16_event_boss.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/09_level_slide.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/18_event_endless_stairs.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/13_event_merry_go_round.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/15_cutscene_star_spawn.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/08_level_snow.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/19_level_boss_koopa_final.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/04_level_inside_castle.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/20_cutscene_ending.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/06_level_hot.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/17_cutscene_collect_key.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/10_event_koopa_message.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/07_level_boss_koopa.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/1E_cutscene_intro.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/0B_event_piranha_plant.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/1C_event_toad_message.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/0A_level_spooky.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/21_menu_file_select.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/0E_event_powerup.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/01_cutscene_collect_star.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/0F_event_metal_cap.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/1F_cutscene_victory.m64
        ${CMAKE_SOURCE_DIR}/sound/sequences/${ROM_VERSION}/0C_level_underground.m64
        -D${ROM_VERSION_STRING}=1
        -DF3D_OLD=1 -DNON_MATCHING=1 -DAVOID_UB=1 -D_FINALROM=1 # TODO
        "$(cat ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth)"
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${ABSOLUTE_BUILD_DIR}/sound/sequences.bin > ${ABSOLUTE_BUILD_DIR}/sound/sequences.bin.inc.c
    COMMAND echo >> ${ABSOLUTE_BUILD_DIR}/sound/sequences.bin.inc.c
    COMMAND hexdump -v -e '1/1 \"0x%X,\"' ${ABSOLUTE_BUILD_DIR}/sound/bank_sets > ${ABSOLUTE_BUILD_DIR}/sound/bank_sets.inc.c
    COMMAND echo >> ${ABSOLUTE_BUILD_DIR}/sound/bank_sets.inc.c
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${ABSOLUTE_BUILD_DIR}/endian-and-bitwidth ${CMAKE_SOURCE_DIR}/tools/assemble_sound.py
    COMMENT "Converting sounds"
)
add_custom_target(convert_sequences ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/sound/bank_sets.inc.c)
add_dependencies(convert_sequences extract_assets assemble_sound_player)
