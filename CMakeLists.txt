cmake_minimum_required(VERSION 3.21...4.0.0)

project(${SKBUILD_PROJECT_NAME} LANGUAGES C)

find_package(Python
  COMPONENTS
    Interpreter
    Development.Module
    NumPy
    ${SKBUILD_SABI_COMPONENT}
  REQUIRED
)

if ("${SKBUILD_SABI_VERSION}" STREQUAL "")
  set(CYTHON_MIN "0.29")
else()
  set(CYTHON_MIN "3.1")
endif()

find_package(Cython ${CYTHON_MIN} REQUIRED)
include(UseCython)

if ("${CYTHON_VERSION}" VERSION_LESS "${CYTHON_MIN}")
  message(FATAL_ERROR "Cython version found: ${CYTHON_VERSION}. Minimum required: ${CYTHON_MIN}")
endif()

find_package(MPI REQUIRED)
find_package(parRSB REQUIRED)

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/src/parrsb.c"
  MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/src/parrsb.pyx"
  VERBATIM
  COMMAND Python::Interpreter -m cython "${CMAKE_CURRENT_SOURCE_DIR}/src/parrsb.pyx" --output-file "${CMAKE_CURRENT_BINARY_DIR}/src/parrsb.c"
)

python_add_library(parrsb MODULE "${CMAKE_CURRENT_BINARY_DIR}/src/parrsb.c" WITH_SOABI)
target_link_libraries(parrsb PRIVATE parRSB::parRSB MPI::MPI_C Python::NumPy)

install(TARGETS parrsb DESTINATION .)
