cmake_minimum_required(VERSION 3.16)
project(hello_ci LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(hello src/hello.cpp)

enable_testing()
add_test(NAME hello_run COMMAND hello)
