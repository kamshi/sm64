# specify the cross compiler
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR mips)

# specify the compiler paths
set(CMAKE_C_COMPILER mips32-elf-gcc)
set(CMAKE_CXX_COMPILER mips32-elf-g++)
set(CMAKE_LINKER mips32-elf-ld)
set(CMAKE_ASM_COMPILER mips32-elf-as)
set(CMAKE_AR mips32-elf-ar)
set(CMAKE_RANLIB mips32-elf-ranlib)
set(CMAKE_OBJCOPY mips32-elf-objcopy)
set(CMAKE_NM mips32-elf-nm)
# skip checks whether compilers are working
set(CMAKE_C_COMPILER_WORKS 1)
set(CMAKE_CXX_COMPILER_WORKS 1)

# optionally, specify the sysroot if available
#set(CMAKE_SYSROOT /path/to/sysroot)

# specify the path to the toolchain's root
#set(CMAKE_FIND_ROOT_PATH /usr/mips-linux /path/to/mips-linux)

# adjust the search paths
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
