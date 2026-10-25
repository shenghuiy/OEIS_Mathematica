# Builds a401118_scip, the SCIP solver behind Method -> "SCIP" in src/wolfram/A401118_SCIP.wl.
# The library and, on Windows, the SCIP and SoPlex DLLs it needs go to lib/ next to this file,
# which is where the package looks for them. See docs/A401118_SCIP.md for the full build steps.
#
#   cmake -S src/c/a401118_scip -B src/c/a401118_scip/build -DSCIP_DIR=<SCIP install>/lib/cmake/scip
#   cmake --build src/c/a401118_scip/build --config Release

cmake_minimum_required(VERSION 3.16)
project(a401118_scip C)

find_package(SCIP CONFIG REQUIRED)

add_library(a401118_scip SHARED a401118_scip.c)
target_link_libraries(a401118_scip PRIVATE libscip)

set(A401118_LIB_DIR "${CMAKE_CURRENT_SOURCE_DIR}/lib")
set_target_properties(a401118_scip PROPERTIES
  PREFIX ""
  RUNTIME_OUTPUT_DIRECTORY "${A401118_LIB_DIR}"
  RUNTIME_OUTPUT_DIRECTORY_RELEASE "${A401118_LIB_DIR}"
  LIBRARY_OUTPUT_DIRECTORY "${A401118_LIB_DIR}"
  LIBRARY_OUTPUT_DIRECTORY_RELEASE "${A401118_LIB_DIR}"
  BUILD_RPATH "${SCIP_DIR}/../..")

# Windows finds a DLL's dependencies on PATH, not next to it, so copy SCIP's DLLs (libscip, libsoplexshared)
# into lib/; the package loads them before the wrapper. Elsewhere BUILD_RPATH points at SCIP's lib directory.
if(WIN32)
  file(GLOB A401118_SCIP_DLLS "${SCIP_DIR}/../../../bin/*.dll")
  add_custom_command(TARGET a401118_scip POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${A401118_SCIP_DLLS} "${A401118_LIB_DIR}")
endif()
