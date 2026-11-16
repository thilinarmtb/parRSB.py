#!/bin/bash
set -e
set -o pipefail

usage() {
  cat <<'EOF'
Usage: bash bin/test.sh [OPTIONS]

Build dependencies and run the tests.

Options:
  --temp-dir DIR      Create a unique temporary directory inside DIR.
                      Creates DIR if needed. Defaults to mktemp's location.
  -h, --help          Show this help and exit.
EOF
}

TEMP_PARENT=

while [ "$#" -gt 0 ]; do
  case "$1" in
    --temp-dir)
      if [ "$#" -lt 2 ] || [ -z "$2" ] || [[ "$2" == --* ]] || [ "$2" = -h ]; then
        printf 'Error: %s requires a value.\n' "$1" >&2
        exit 1
      fi
      TEMP_PARENT=$2
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n\n' "$1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

: ${CC:=mpicc}
: ${UV:=uv}
: ${CMAKE:=cmake}
: ${FC:=gfortran}
: ${MPIRUN:=mpirun}
: ${MPIOPTS:=}
: ${NP:=4}

############################
# Don't touch what follows #
############################
TEMP_TEMPLATE="parrsb.$(date +%m_%d_%y_%H_%M_%S)_XXXXXXXX"
if [ -n "$TEMP_PARENT" ]; then
  mkdir -p -- "$TEMP_PARENT"
  TEMP_PARENT=$(cd -- "$TEMP_PARENT" && pwd -P)
  WRK_DIR=$(mktemp -d "${TEMP_PARENT}/${TEMP_TEMPLATE}")
else
  WRK_DIR=$(mktemp -d "${TMPDIR:-/tmp}/${TEMP_TEMPLATE}")
fi
VENV=${WRK_DIR}/.venv
NEK5K_DIR=${WRK_DIR}/Nek5000
GSLIB_DIR=${WRK_DIR}/gslib
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
  CC=${CC} FC=${FC} ./maketools genbox/
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
  VIRTUAL_ENV=${VENV} ${UV} sync --no-install-project --active
}

function build_gslib() {
  git clone https://github.com/thilinarmtb/gslib.git ${GSLIB_DIR}
  cmake -B ${GSLIB_DIR}/build -S ${GSLIB_DIR} -DCMAKE_INSTALL_PREFIX=${VENV}
  cmake --build ${GSLIB_DIR}/build --target install
}

function build_parrsb() {
  git clone https://github.com/thilinarmtb/parRSB.git ${PARRSB_DIR}
  CC=${CC} ${CMAKE} -B ${PARRSB_DIR}/build -S ${PARRSB_DIR} \
    -DCMAKE_INSTALL_PREFIX=${VENV} -Dgs_DIR=${VENV}/lib/cmake/gs
  ${CMAKE} --build ${PARRSB_DIR}/build --target install
}

function build_parrsb_py() {
  ${UV} pip install --python "${VENV}/bin/python" \
    --reinstall --no-cache . \
    -Ccmake.define.parRSB_DIR="${VENV}/lib/cmake/parRSB"
}

#function build_parrsb_py() {
#  ${UV} pip install . --target ${VENV} -vv \
#    -Ccmake.define.parRSB_DIR=${VENV}/lib/cmake/parRSB
#}

#############
# Run tests #
#############
function run_tests() {
  export LD_LIBRARY_PATH="${VENV}/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
  export DYLD_LIBRARY_PATH="${VENV}/lib${DYLD_LIBRARY_PATH:+:$DYLD_LIBRARY_PATH}"

  for path in ./tests/*.py; do
    file=$(basename "${path}")
    ${MPIRUN} ${MPIOPTS} -np "${NP}" "${VENV}/bin/python" \
      "${path}" "${WRK_DIR}/${file/.py/}"
  done
}

#function run_tests() {
#  source ${VENV}/bin/activate
#
#  export LD_LIBRARY_PATH=${VENV}/lib:${LD_LIBRARY_PATH}
#  export DYLD_LIBRARY_PATH=${VENV}/lib:${DYLD_LIBRARY_PATH}

#  for path in `ls ./tests/*.py`; do
#    file=$(basename ${path})
#    ${MPIRUN} ${MPIOPTS} -np ${NP} ${UV} run --active --python ${VENV} \
#      ${path} ${WRK_DIR}/${file/.py/}
#  done

 # deactivate
#}

GREEN='\033[0;32m'
RESET='\033[0m'

echo -e "${GREEN}"
echo "Running tests in ${WRK_DIR} ..."
echo "  CC    : ${CC}"
echo "  FC    : ${FC}"
echo "  uv    : `which ${UV}`"
echo "  cmake : `which ${CMAKE}`"
echo "  mpirun: `which ${MPIRUN}`, opts: \"${MPIOPTS} -np ${NP}\""
echo -e "${RESET}"
init_venv
build_gslib
build_parrsb
build_parrsb_py
build_genbox
build_meshes
run_tests
echo -e "${GREEN}Tests passed.${RESET}"

