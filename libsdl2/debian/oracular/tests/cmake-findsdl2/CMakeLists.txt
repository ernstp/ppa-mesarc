# Copyright 2019 Collabora Ltd.
# SPDX-License-Identifier: Zlib
# (see "zlib/libpng" in debian/copyright)

cmake_minimum_required(VERSION 3.13)
project(Hello)

list(INSERT CMAKE_MODULE_PATH 0 "${CMAKE_SOURCE_DIR}")

find_package(SDL2 REQUIRED)
include_directories(${SDL2_INCLUDE_DIR})

add_executable(hello hello.c)
target_link_libraries(hello SDL2)
