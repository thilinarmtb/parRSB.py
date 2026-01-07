## Python wrappers for parRSB

### Building the library

`parRSB.py` depends on [gslib](https://github.com/Nek5000/gslib.git) and
[parRSB](https://github.com/thilinarmtb/parRSB.git). The `Makefile` found
at the root of this repository downloads and builds these dependencies (so
no need to manually download and build them).

This project also uses `uv` for managing Python virtual environments. You
can install it by following the instructions [here](https://docs.astral.sh/uv/getting-started/installation/).

After installing `uv`, you can download and build the python wrappers by
running:
```sh
git clone https://github.com/thilinarmtb/parRSB.py.git
cd parRSB.py
make
```
