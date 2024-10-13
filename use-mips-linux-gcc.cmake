# specify the cross compiler
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR mips)

# specify the compiler paths
set(CMAKE_C_COMPILER mips-linux-gcc)
#set(CMAKE_CXX_COMPILER mips-linux-g++)
set(CMAKE_LINKER mips-linux-ld)
set(CMAKE_ASM_COMPILER mips-linux-as)
set(CMAKE_AR mips-linux-ar)
set(CMAKE_RANLIB mips-linux-ranlib)
set(CMAKE_NM mips-linux-nm)

# optionally, specify the sysroot if available
#set(CMAKE_SYSROOT /path/to/sysroot)

# specify the path to the toolchain's root
#set(CMAKE_FIND_ROOT_PATH /usr/mips-linux /path/to/mips-linux)

# adjust the search paths
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
