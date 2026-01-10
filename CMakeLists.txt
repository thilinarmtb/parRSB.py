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

include(ExternalProject)

ExternalProject_Add(gslib_ext
  PREFIX "${CMAKE_BINARY_DIR}/gslib"
  GIT_REPOSITORY "https://github.com/Nek5000/gslib.git"
  GIT_TAG "master"
  CONFIGURE_COMMAND ""
  BUILD_COMMAND CC=${MPI_C_COMPILER} make SHARED=1 STATIC=0
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND ""
)
ExternalProject_Get_Property(gslib_ext SOURCE_DIR)
set(GSLIB_DIR ${SOURCE_DIR}/build)

ExternalProject_Add(parRSB_ext
  PREFIX "${CMAKE_BINARY_DIR}/parRSB"
  GIT_REPOSITORY "https://github.com/thilinarmtb/parRSB.git"
  GIT_TAG "general_graph"
  CONFIGURE_COMMAND ""
  BUILD_COMMAND CC=${MPI_C_COMPILER} GSLIB_DIR=${GSLIB_DIR} make
  BUILD_IN_SOURCE 1
  INSTALL_COMMAND ""
  DEPENDS gslib_ext
)
ExternalProject_Get_Property(parRSB_ext SOURCE_DIR)
set(PARRSB_DIR ${SOURCE_DIR}/install)

add_custom_command(
  OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/src/parrsb.c"
  MAIN_DEPENDENCY "${CMAKE_CURRENT_SOURCE_DIR}/src/parrsb.pyx"
  VERBATIM
  COMMAND Python::Interpreter -m cython "${CMAKE_CURRENT_SOURCE_DIR}/src/parrsb.pyx" --output-file "${CMAKE_CURRENT_BINARY_DIR}/src/parrsb.c"
  DEPENDS parRSB_ext
)

python_add_library(parrsb MODULE "${CMAKE_CURRENT_BINARY_DIR}/src/parrsb.c" WITH_SOABI)
target_include_directories(parrsb PRIVATE ${PARRSB_DIR}/include ${GSLIB_DIR}/include)
target_link_libraries(parrsb PRIVATE MPI::MPI_C Python::NumPy)

install(TARGETS parrsb LIBRARY DESTINATION .)
