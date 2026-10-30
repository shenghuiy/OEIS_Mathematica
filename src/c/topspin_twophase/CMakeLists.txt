# Builds topspin_twophase, the prototype two-phase TopSpin solver described in docs/TopSpinTwoPhase.md,
# and topspin_twophase_bench, the same code with a benchmark main. Both go to build/ at the repository root.
# OpenMP is used when the compiler has it; without it the search runs on one thread.
#
#   cmake -S src/c/topspin_twophase -B build/topspin_twophase -DCMAKE_BUILD_TYPE=Release
#   cmake --build build/topspin_twophase --config Release

cmake_minimum_required(VERSION 3.16)
project(topspin_twophase C)

get_filename_component(TOPSPIN_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(TOPSPIN_LIB_DIR "${TOPSPIN_ROOT}/build")

find_package(OpenMP COMPONENTS C)

add_library(topspin_twophase SHARED topspin_twophase.c)
add_executable(topspin_twophase_bench topspin_twophase.c)
target_compile_definitions(topspin_twophase_bench PRIVATE TOPSPIN_TP_MAIN)

foreach(target topspin_twophase topspin_twophase_bench)
  if(OpenMP_C_FOUND)
    target_link_libraries(${target} PRIVATE OpenMP::OpenMP_C)
  endif()
  if(MSVC)
    target_compile_definitions(${target} PRIVATE _CRT_SECURE_NO_WARNINGS)
  endif()
  set_target_properties(${target} PROPERTIES
    PREFIX ""
    C_VISIBILITY_PRESET hidden
    RUNTIME_OUTPUT_DIRECTORY "${TOPSPIN_LIB_DIR}"
    RUNTIME_OUTPUT_DIRECTORY_RELEASE "${TOPSPIN_LIB_DIR}"
    LIBRARY_OUTPUT_DIRECTORY "${TOPSPIN_LIB_DIR}"
    LIBRARY_OUTPUT_DIRECTORY_RELEASE "${TOPSPIN_LIB_DIR}")
endforeach()
