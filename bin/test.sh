#!/bin/bash
set -x
set -e
set -o pipefail

: ${CC:=mpicc}
: ${UV:=uv}
: ${CMAKE:=cmake}
: ${MPIRUN:=mpirun}
: ${MPIOPTS:=}
: ${NP:=4}

############################
# Don't touch what follows #
############################
WRK_DIR=$(mktemp -d)
VENV=${WRK_DIR}/.venv
NEK5K_DIR=${WRK_DIR}/Nek5000
PARRSB_DIR=${WRK_DIR}/parRSB

#############################################
# Functions to help build Nek5000/RS meshes #
#############################################
function build_genbox() {
  if [ -f ${NEK5K_DIR}/bin/genbox ]; then
    return
  fi

  if [ ! -d ${NEK5K_DIR} ]; then
    git clone https://github.com/Nek5000/Nek5000.git ${NEK5K_DIR}
  fi

  # We have to change directory due to the way makenek script is written.
  cwd=${PWD}
  cd ${NEK5K_DIR}/tools
  CC=gcc FC=gfortran ./maketools genbox/
  cd ${cwd}
}

function build_mesh() {
  export PATH=${PATH}:${NEK5K_DIR}/bin

  genbox << EOF
$1
EOF

  name=$(basename "$1")
  mv box.re2 ${WRK_DIR}/${name/.box/.re2}
}

function build_meshes() {
  for file in `ls ./tests/box/*.box`; do
    build_mesh $file
  done
}

#############################################
# Functions to help build parRSB/parRSB.py  #
#############################################
function init_venv() {
  VIRTUAL_ENV=${VENV} ${UV} sync --active --no-install-project
}

function build_parrsb() {
  git clone https://github.com/thilinarmtb/parRSB.git -b general_graph ${PARRSB_DIR}
  CC=${CC} ${CMAKE} -B ${PARRSB_DIR}/build -S ${PARRSB_DIR} -DCMAKE_INSTALL_PREFIX=${VENV}
  ${CMAKE} --build ${PARRSB_DIR}/build --target install
}

function build_parrsb_py() {
  source ${VENV}/bin/activate
  ${UV} pip install . --target ${VENV} -vv -Ccmake.define.parRSB_DIR=${VENV}
}

#############
# Run tests #
#############
function run_tests() {
  export LD_LIBRARY_PATH=${VENV}/lib:${LD_LIBRARY_PATH}
  export DYLD_LIBRARY_PATH=${VENV}/lib:${DYLD_LIBRARY_PATH}

  for path in `ls ./tests/*.py`; do
    file=$(basename ${path})
    ${MPIRUN} ${MPIOPTS} -np ${NP} ${UV} run --python ${VENV} ${path} ${WRK_DIR}/${file/.py/}
  done
}

echo "Running tests in ${WRK_DIR} with CC=${CC}, uv=`which ${UV}`, cmake=`which ${CMAKE}`"
build_genbox
build_meshes
init_venv
build_parrsb
build_parrsb_py
run_tests
