﻿# specify the cross compiler
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR mips)

# specify the compiler paths
set(CMAKE_C_COMPILER mips64-linux-gnu-gcc)
#set(CMAKE_CXX_COMPILER mips64-linux-gnu-g++)
set(CMAKE_LINKER mips64-linux-gnu-ld)
set(CMAKE_ASM_COMPILER mips64-linux-gnu-as)
set(CMAKE_AR mips64-linux-gnu-ar)
set(CMAKE_RANLIB mips64-linux-gnu-ranlib)
set(CMAKE_OBJCOPY mips64-linux-gnu-objcopy)
set(CMAKE_NM mips64-linux-gnu-nm)

# optionally, specify the sysroot if available
#set(CMAKE_SYSROOT /path/to/sysroot)

# specify the path to the toolchain's root
#set(CMAKE_FIND_ROOT_PATH /usr/mips-linux-gnu /path/to/mips-linux-gnu)

# adjust the search paths
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
