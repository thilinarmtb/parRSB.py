# parRSB.py

Python wrappers for [parRSB](https://github.com/thilinarmtb/parRSB) - a library for
parallel graph partitioning using Recursive Spectral Bisection (RSB).

## Overview

`parRSB.py` provides Cython-based Python bindings for the `parRSB` C library. It
exposes functionality for:

- **Partitioning graphs** using RSB and other algorithms.
- **Reading Nek5000/NekRS  meshes** from `.re2` files.
- **Calculating mesh connectivity** based on node coordinates.

The library is built on top of:
- [parRSB](https://github.com/thilinarmtb/parRSB) - C library for parallel mesh partitioning.
- [gslib](https://github.com/Nek5000/gslib) - Highly scalable communication library.
- [mpi4py](https://mpi4py.readthedocs.io) - MPI for Python.
- [NumPy](https://numpy.org) - for array handling.

## Requirements

### System Dependencies

- A C compiler with MPI support (e.g., `mpicc` via [OpenMPI](https://www.open-mpi.org/))
- CMake (>= 3.21)

On Ubuntu/Debian, install them with:

```sh
sudo apt -y update
sudo apt install -y openmpi-bin libopenmpi-dev
sudo apt install -y cmake
```

### Python Requirements

- Python >= 3.10
- [`uv`](https://docs.astral.sh/uv/) for virtual environment and package management

Install `uv` by following the instructions [here](https://docs.astral.sh/uv/getting-started/installation/).

## Installation

### 1. Clone and build parRSB

First, build and install the `parRSB` C library into a virtual environment directory:

```sh
uv venv .venv
git clone https://github.com/thilinarmtb/parRSB.git -b general_graph
cd parRSB
cmake -B build -S . -DCMAKE_INSTALL_PREFIX=../.venv
cmake --build build --target install
cd ..
```

### 2. Build and install parRSB.py

```sh
source .venv/bin/activate
uv pip install . --target .venv -Ccmake.define.parRSB_DIR=.venv
```

> **Note:** The `CC=mpicc` environment variable should be set so that the C extension is compiled with MPI support.
