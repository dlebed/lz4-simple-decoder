cmake_minimum_required(VERSION 3.26)
project(lz4 C)

set(CMAKE_C_STANDARD 23)

add_executable(lz4 main.c lz4.c)
