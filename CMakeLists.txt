cmake_minimum_required(VERSION 3.15)
project(NeuroGenetica CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Incluir Raylib automáticamente vía FetchContent
include(FetchContent)
FetchContent_Declare(
    raylib
    GIT_REPOSITORY https://github.com/raysan5/raylib.git
    GIT_TAG 5.0
    GIT_SHALLOW TRUE
)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(raylib)

# Fuentes del proyecto
file(GLOB_RECURSE SOURCES "src/*.cpp")

add_executable(NeuroGenetica ${SOURCES})

target_include_directories(NeuroGenetica PRIVATE 
    include
    include/core
    include/ai
    include/graphics
)

target_link_libraries(NeuroGenetica PRIVATE raylib)
