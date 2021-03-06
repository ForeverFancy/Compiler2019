project(SubtreeVSHashingSim)
cmake_minimum_required( VERSION 2.8 )

set(CMAKE_C_FLAGS "${CMAKE_CXX_FLAGS}")

set(CMAKE_BUILD_TYPE "Debug")
set(CMAKE_C_FLAGS_DEBUG "$ENV{CXXFLAGS} -O0 -Wall -g2 -ggdb")
set(CMAKE_C_FLAGS_RELEASE "$ENV{CXXFLAGS} -O3 -Wall")

find_package(FLEX REQUIRED)
find_package(BISON REQUIRED)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR})
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/lib)

include_directories(${PROJECT_SOURCE_DIR})
include_directories(${PROJECT_BINARY_DIR})

add_subdirectory(common)
add_subdirectory(syntax_tree)

add_subdirectory(lab1_lexical_analyzer)
add_subdirectory(lab2_syntax_analyzer)

add_executable(c-c
	cminus_compiler.c
)
target_link_libraries(c-c lex syntax)
