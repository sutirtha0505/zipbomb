# Minimum CMake version
cmake_minimum_required(VERSION 3.15)

# Project name and language
project(zipbomb C)

# Set C standard
set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Set output directory for binaries
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)

# Try to find zlib in different ways
find_package(ZLIB QUIET)

if(NOT ZLIB_FOUND)
    # Try to find zlib manually (for MinGW/MSYS2)
    find_path(ZLIB_INCLUDE_DIR zlib.h
        PATHS
        C:/MinGW/include
        /usr/include
        /usr/local/include
        ${CMAKE_PREFIX_PATH}/include
        C:/msys64/mingw64/include
        C:/msys64/usr/include
    )
    
    find_library(ZLIB_LIBRARY
        NAMES z zlib zdll
        PATHS
        C:/MinGW/lib
        /usr/lib
        /usr/local/lib
        ${CMAKE_PREFIX_PATH}/lib
        C:/msys64/mingw64/lib
        C:/msys64/usr/lib
    )
    
    if(ZLIB_INCLUDE_DIR AND ZLIB_LIBRARY)
        set(ZLIB_FOUND TRUE)
        set(ZLIB_LIBRARIES ${ZLIB_LIBRARY})
        set(ZLIB_INCLUDE_DIRS ${ZLIB_INCLUDE_DIR})
        message(STATUS "Found zlib manually: ${ZLIB_LIBRARY}")
    endif()
endif()

if(NOT ZLIB_FOUND)
    message(FATAL_ERROR "zlib not found! Please install zlib:
    - For MSYS2: pacman -S mingw-w64-x86_64-zlib
    - For vcpkg: vcpkg install zlib:x64-windows
    - Or download from https://zlib.net/")
endif()

# Source file
add_executable(zipbomb main.c)

# Link zlib
if(TARGET ZLIB::ZLIB)
    target_link_libraries(zipbomb PRIVATE ZLIB::ZLIB)
else()
    target_include_directories(zipbomb PRIVATE ${ZLIB_INCLUDE_DIRS})
    target_link_libraries(zipbomb PRIVATE ${ZLIB_LIBRARIES})
endif()

# Handle Windows-specific issues
if(WIN32)
    # Add Windows-specific definitions
    target_compile_definitions(zipbomb PRIVATE _CRT_SECURE_NO_WARNINGS)
    target_compile_definitions(zipbomb PRIVATE WIN32_LEAN_AND_MEAN)
endif()

# Compiler flags
if(MSVC)
    target_compile_options(zipbomb PRIVATE /W4)
else()
    target_compile_options(zipbomb PRIVATE -Wall -Wextra -O2)
endif()

# Print some info
message(STATUS "Building zipbomb with zlib support")
message(STATUS "ZLIB found: ${ZLIB_FOUND}")
if(ZLIB_VERSION_STRING)
    message(STATUS "ZLIB version: ${ZLIB_VERSION_STRING}")
endif()
