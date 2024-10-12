cmake_minimum_required(VERSION 3.10)

if("${ROM_VERSION}" STREQUAL "jp")
    include(assets_jp.cmake)

    add_custom_command(
        OUTPUT ${ASSETS_JP}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/extract_assets.py ${ROM_VERSION}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        DEPENDS ${CMAKE_SOURCE_DIR}/extract_assets.py
        COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/extract_assets.py..."
    )
    add_custom_target(extract_assets DEPENDS ${ASSETS_JP})
elseif("${ROM_VERSION}" STREQUAL "eu")
    include(assets_eu.cmake)

    add_custom_command(
        OUTPUT ${ASSETS_EU}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/extract_assets.py ${ROM_VERSION}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        DEPENDS ${CMAKE_SOURCE_DIR}/extract_assets.py
        COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/extract_assets.py..."
    )
    add_custom_target(extract_assets DEPENDS ${ASSETS_EU})
elseif("${ROM_VERSION}" STREQUAL "us")
    include(assets_us.cmake)

    add_custom_command(
        OUTPUT ${ASSETS_US}
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_SOURCE_DIR}/extract_assets.py ${ROM_VERSION}
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        DEPENDS ${CMAKE_SOURCE_DIR}/extract_assets.py
        COMMENT "Running Python script ${CMAKE_SOURCE_DIR}/extract_assets.py..."
    )
    add_custom_target(extract_assets DEPENDS ${ASSETS_US})
endif()
