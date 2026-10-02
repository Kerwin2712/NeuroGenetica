cmake_minimum_required(VERSION 3.15)

# Compatibilidad con dependencias que usan políticas de CMake anteriores a 3.5 en CMake 4.x
set(CMAKE_POLICY_VERSION_MINIMUM 3.5 CACHE STRING "" FORCE)

project(NeuroGenetica CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Incluir Raylib automáticamente vía FetchContent
include(FetchContent)
FetchContent_Declare(
    raylib
    GIT_REPOSITORY https://github.com/raysan5/raylib.git
    GIT_TAG 5.5
    GIT_SHALLOW TRUE
)
set(BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(raylib)

# Fuentes del proyecto principal
file(GLOB_RECURSE SOURCES "src/*.cpp")

add_executable(NeuroGenetica ${SOURCES})

target_include_directories(NeuroGenetica PRIVATE 
    include
    include/core
    include/ai
    include/graphics
)

target_link_libraries(NeuroGenetica PRIVATE raylib)

# Ejecutable para Pruebas Unitarias de QuadTree y Geometría
add_executable(QuadTreeTests 
    tests/test_quadtree.cpp 
    src/core/QuadTree.cpp
)
target_include_directories(QuadTreeTests PRIVATE 
    include
    include/core
)
target_link_libraries(QuadTreeTests PRIVATE raylib)

# Ejecutable para Pruebas Unitarias de Red Neuronal (Fase 3)
add_executable(NeuralNetworkTests 
    tests/test_neural_network.cpp 
    src/ai/NeuralNetwork.cpp
)
target_include_directories(NeuralNetworkTests PRIVATE 
    include
    include/ai
)

# Ejecutable para Pruebas Unitarias de Algoritmo Genético y Max-Heap (Fase 4)
add_executable(GeneticAlgorithmTests 
    tests/test_genetic_algorithm.cpp 
    src/ai/GeneticAlgorithm.cpp
    src/ai/NeuralNetwork.cpp
    src/core/Car.cpp
    src/core/Track.cpp
    src/core/QuadTree.cpp
)
target_include_directories(GeneticAlgorithmTests PRIVATE 
    include
    include/core
    include/ai
)
target_link_libraries(GeneticAlgorithmTests PRIVATE raylib)
