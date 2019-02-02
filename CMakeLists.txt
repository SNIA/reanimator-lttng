cmake_minimum_required(VERSION 3.0.0)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_FLAGS "-g -O4")

project(lttng-client)

add_executable(lttng-client lttng-client.cpp)
target_link_libraries(lttng-client boost_program_options)

add_executable(lttng-read-buffer lttng-read-buffer.cpp)
add_subdirectory(Tests)
