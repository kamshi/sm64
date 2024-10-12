cmake_minimum_required(VERSION 3.10)

set(LIBULTRA_OBJECT_FILES)
macro(assemble_libultra_file INPUT_FILE OUTPUT_FILE)
    get_filename_component(OUTPUT_DIR "${OUTPUT_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${OUTPUT_FILE}" NAME)

    add_custom_command(
        OUTPUT ${OUTPUT_FILE}
        COMMAND ${CMAKE_COMMAND} -E make_directory ${OUTPUT_DIR}
        COMMAND clang -E -P -x c -Wno-trigraphs -D_LANGUAGE_ASSEMBLY
                -I${CMAKE_SOURCE_DIR}/include
                -I${ABSOLUTE_BUILD_DIR}
                -I${ABSOLUTE_BUILD_DIR}/include
                -I${CMAKE_SOURCE_DIR}/src
                -I${CMAKE_SOURCE_DIR}
                -I${CMAKE_SOURCE_DIR}/include/libc
                -D${ROM_VERSION_STRING}=1
                # TODO
                -DF3D_OLD=1
                -DNON_MATCHING=1
                -DAVOID_UB=1
                -D_FINALROM=1
                -o ${OUTPUT_FILE}.temp
                ${INPUT_FILE}
        COMMAND ${CMAKE_ASM_COMPILER}
                -march=vr4300 -mabi=32
                -I${CMAKE_SOURCE_DIR}/include
                -I${ABSOLUTE_BUILD_DIR}
                -I${ABSOLUTE_BUILD_DIR}/include
                -I${CMAKE_SOURCE_DIR}/src
                -I${CMAKE_SOURCE_DIR}
                -I${CMAKE_SOURCE_DIR}/include/libc
                --defsym ${ROM_VERSION_STRING}=1
                # TODO: defsym
                --defsym F3D_OLD=1
                --defsym NON_MATCHING=1
                --defsym AVOID_UB=1
                --defsym _FINALROM=1
                -MD ${OUTPUT_FILE}.d
                -o ${OUTPUT_FILE}
                ${OUTPUT_FILE}.temp
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        DEPENDS ${INPUT_FILE}
        COMMENT "Assembling file ${INPUT_FILE}"
    )
    list(APPEND LIBULTRA_OBJECT_FILES ${OUTPUT_FILE})
endmacro()

# IMPORTANT: the order here matters for the linking stage
set(LIB_ASSEMBLY_FILES
    lib/asm/__osGetSR.s
    lib/asm/iQueKernelCalls.s
    lib/asm/__osDisableInt.s
    lib/asm/osGetCount.s
    lib/asm/__os_eu_802ef550.s
    lib/asm/__osSetFpcCsr.s
    lib/asm/bcopy.s
    lib/asm/__osGetCause.s
    lib/asm/__osSetCompare.s
    lib/asm/llmuldiv_gcc.s
    lib/asm/osWritebackDCacheAll.s
    lib/asm/guScale.s
    lib/asm/parameters.s
    lib/asm/osMapTLBRdb.s
    lib/asm/bzero.s
    lib/asm/osInvalDCache.s
    lib/asm/sqrtf.s
    lib/asm/__osExceptionPreamble.s
    lib/asm/guMtxF2L.s
    lib/asm/osUnmapTLBAll.s
    lib/asm/osSetIntMask.s
    lib/asm/guTranslate.s
    lib/asm/osInvalICache.s
    lib/asm/__osRestoreInt.s
    lib/asm/guNormalize.s
    lib/asm/__osSetSR.s
    lib/asm/__osProbeTLB.s
    lib/asm/osMapTLB.s
    lib/asm/osWritebackDCache.s
    lib/asm/guMtxIdentF.s
    lib/asm/__osSetWatchLo.s
)
foreach(ASSEMBLY_FILE ${LIB_ASSEMBLY_FILES})
    get_filename_component(OUTPUT_DIR "${ASSEMBLY_FILE}" DIRECTORY)
    get_filename_component(OUTPUT_FILENAME "${ASSEMBLY_FILE}" NAME_WLE)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OUTPUT_DIR}")
    assemble_libultra_file(${ASSEMBLY_FILE} "${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${OUTPUT_FILENAME}.o")
endforeach()
add_custom_target(assemble_libultra DEPENDS ${LIBULTRA_OBJECT_FILES})

# IMPORTANT: the order here matters for the linking stage
set(LIBULTRA_SOURCE_FILES
    lib/src/contramwrite.c
    lib/src/osAiGetLength.c
    lib/src/osPiStartDma.c
    lib/src/guOrthoF.c
    lib/src/osViSetMode.c
    lib/src/__osGetCurrFaultedThread.c
    lib/src/__osDevMgrMain.c
    lib/src/osContStartReadData.c
    lib/src/osViTable.c
    lib/src/leointerrupt.c
    lib/src/__osSpSetStatus.c
    lib/src/string.c
    lib/src/osEepromRead.c
    lib/src/osEepromWrite.c
    lib/src/__osAtomicDec.c
    lib/src/osSetEventMesg.c
    lib/src/__osViInit.c
    lib/src/__osSiRawStartDma.c
    lib/src/osSyncPrintf.c
    lib/src/kdebugserver_stack.c
    lib/src/contramread.c
    lib/src/osCreateViManager.c
    lib/src/__osSpGetStatus.c
    lib/src/osSetThreadPri.c
    lib/src/osViData.c
    lib/src/guRotateF.c
    lib/src/__osSetHWintrRoutine.c
    lib/src/__osSiCreateAccessQueue.c
    lib/src/osGetThreadPri.c
    lib/src/osPfsIsPlug.c
    lib/src/osJamMesg.c
    lib/src/osEepromLongRead.c
    lib/src/osSetTimer.c
    lib/src/osEPiRawWriteIo.c
    lib/src/pfsgetstatus.c
    lib/src/epidma.c
    lib/src/__osSiRawReadIo.c
    lib/src/osCreateMesgQueue.c
    lib/src/NaN.c
    lib/src/osTimer.c
    lib/src/_Printf.c
    lib/src/guMtxF2L.c
    lib/src/__osSpDeviceBusy.c
    lib/src/osEepromProbe.c
    lib/src/__osSiRawWriteIo.c
    lib/src/osSpTaskYielded.c
    lib/src/__osSetGlobalIntMask.c
    lib/src/osEPiRawStartDma.c
    lib/src/osCreateThread.c
    lib/src/__osSpRawStartDma.c
    lib/src/osViBlack.c
    lib/src/guTranslateF.c
    lib/src/osAiSetNextBuffer.c
    lib/src/osDestroyThread.c
    lib/src/_Ldtob.c
    lib/src/osEPiRawReadIo.c
    lib/src/guNormalize.c
    lib/src/osRecvMesg.c
    lib/src/kdebugserver.c
    lib/src/__osPiCreateAccessQueue.c
    lib/src/alBnkfNew.c
    lib/src/__osViSwapContext.c
    lib/src/osDriveRomInit.c
    lib/src/__osViGetCurrentContext.c
    lib/src/motor.c
    lib/src/osPiRawStartDma.c
    lib/src/osSpTaskYield.c
    lib/src/osPiRawReadIo.c
    lib/src/osAiSetFrequency.c
    lib/src/guScaleF.c
    lib/src/__osResetGlobalIntMask.c
    lib/src/__osSiDeviceBusy.c
    lib/src/osPiGetCmdQueue.c
    lib/src/osSetTime.c
    lib/src/__osDequeueThread.c
    lib/src/osVirtualToPhysical.c
    lib/src/__osSyncPutChars.c
    lib/src/crc.c
    lib/src/ldiv.c
    lib/src/osCartRomInit.c
    lib/src/osSendMesg.c
    lib/src/osContInit.c
    lib/src/guLookAtRef.c
    lib/src/osLeoDiskInit.c
    lib/src/osYieldThread.c
    lib/src/sprintf.c
    lib/src/osInitializeIQueWrapper.c
    lib/src/osViSetEvent.c
    lib/src/_Litob.c
    lib/src/osViSetSpecialFeatures.c
    lib/src/osStartThread.c
    lib/src/osViSwapBuffer.c
    lib/src/__osAiDeviceBusy.c
    lib/src/osEepromLongWrite.c
    lib/src/osGetTime.c
    lib/src/__osSpSetPc.c
    lib/src/osCreatePiManager.c
    lib/src/guPerspectiveF.c
    lib/src/osInitialize.c
    lib/src/osSpTaskLoadGo.c
    lib/src/math/llmuldiv.c
    lib/src/math/sinf.c
    lib/src/math/llconv.c
    lib/src/math/cosf.c
)

foreach(SOURCE_FILE ${LIBULTRA_SOURCE_FILES})
    # Get the filename without extension
    get_filename_component(FILE_NAME ${SOURCE_FILE} NAME_WE)
    get_filename_component(SOURCE_DIR "${SOURCE_FILE}" DIRECTORY)
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${SOURCE_DIR}")
    # Set the object file name
    set(OBJECT_FILE ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${FILE_NAME}.o)
    set(ABS_OBJECT_FILE ${ABSOLUTE_BUILD_DIR}/${RELATIVE_PATH}/${FILE_NAME}.o)
    set(DEPENDENCY_FILE ${RELATIVE_BUILD_DIR}/${RELATIVE_PATH}/${FILE_NAME}.d)

    # Add a custom command to compile the source file
    add_custom_command(
        OUTPUT ${ABS_OBJECT_FILE}
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
        COMMENT "Compiling ${CMAKE_SOURCE_DIR}/${SOURCE_FILE} -> ${OBJECT_FILE}"
    )

    # Append the object file to the list of object files
    list(APPEND LIBULTRA_OBJECT_FILES ${ABS_OBJECT_FILE})
endforeach()

set(RELATIVE_LIBULTRA_OBJECT_FILES)
foreach(OBJECT_FILE ${LIBULTRA_OBJECT_FILES})
    string(REPLACE "${CMAKE_SOURCE_DIR}/" "" RELATIVE_PATH "${OBJECT_FILE}")
    list(APPEND RELATIVE_LIBULTRA_OBJECT_FILES ${RELATIVE_PATH})
endforeach()

add_custom_command(
    OUTPUT ${ABSOLUTE_BUILD_DIR}/libultra.a
    COMMAND ${CMAKE_COMMAND} -E make_directory ${ABSOLUTE_BUILD_DIR}
    # link
    COMMAND ${CMAKE_AR}
            rcs -o ${RELATIVE_BUILD_DIR}/libultra.a
            ${RELATIVE_LIBULTRA_OBJECT_FILES}
    COMMAND ${CMAKE_SOURCE_DIR}/tools/patch_elf_32bit ${RELATIVE_BUILD_DIR}/libultra.a
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    DEPENDS ${LIBULTRA_OBJECT_FILES} patch_elf_32bit
    COMMENT "Linking libultra"
)

add_custom_target(libultra ALL DEPENDS ${ABSOLUTE_BUILD_DIR}/libultra.a)
