# Builds a401118_scip, the SCIP solver behind Method -> "SCIP" in src/wolfram/A401118_SCIP.wl.
# The library and, on Windows, the SCIP and SoPlex DLLs it needs go to build/ at the repository root,
# which is where the package looks for them. SCIP is found in build/install, where the steps in
# docs/A401118_SCIP.md install it from the scip and soplex submodules; -DSCIP_DIR=... names another install.
#
#   cmake -S src/c/a401118_scip -B build/a401118_scip -DCMAKE_BUILD_TYPE=Release
#   cmake --build build/a401118_scip --config Release

cmake_minimum_required(VERSION 3.16)
project(a401118_scip C)

get_filename_component(A401118_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../.." ABSOLUTE)
set(SCIP_DIR "${A401118_ROOT}/build/install/lib/cmake/scip" CACHE PATH "Directory of SCIP's scip-config.cmake")

find_package(SCIP CONFIG REQUIRED)

add_library(a401118_scip SHARED a401118_scip.c)
target_link_libraries(a401118_scip PRIVATE libscip)

set(A401118_LIB_DIR "${A401118_ROOT}/build")
set_target_properties(a401118_scip PROPERTIES
  PREFIX ""
  RUNTIME_OUTPUT_DIRECTORY "${A401118_LIB_DIR}"
  RUNTIME_OUTPUT_DIRECTORY_RELEASE "${A401118_LIB_DIR}"
  LIBRARY_OUTPUT_DIRECTORY "${A401118_LIB_DIR}"
  LIBRARY_OUTPUT_DIRECTORY_RELEASE "${A401118_LIB_DIR}"
  BUILD_RPATH "${SCIP_DIR}/../..")

# Windows finds a DLL's dependencies on PATH, not next to it, so copy SCIP's DLLs (libscip, libsoplexshared)
# into build/; the package loads them before the wrapper. Elsewhere BUILD_RPATH points at SCIP's lib directory.
if(WIN32)
  file(GLOB A401118_SCIP_DLLS "${SCIP_DIR}/../../../bin/*.dll")
  add_custom_command(TARGET a401118_scip POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${A401118_SCIP_DLLS} "${A401118_LIB_DIR}")
endif()
