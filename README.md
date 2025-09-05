## Python wrappers for parRSB

### Building the library

`parRSB.py` depends on [gslib]() and [parRSB](). Please follow the commands
below to download and install them. We need the dynamic (or shared) versions
of the above libraries (not the default static version).

Install `gslib`:
```sh
git clone https://github.com/Nek5000/gslib.git
cd gslib
CC=mpicc DESTDIR=./install make SHARED=1 STATIC=0
cd ..
```

Then install `parRSB`:
```sh
git clone https://github.com/thilinarmtb/parRSB.git -b general_graph
cd parRSB
export GSLIBPATH=../gslib/install
CC=mpicc DESTDIR=./install make install SHARED=1
cd ..
```

Finally build the wrappers:
```sh
git clone https://github.com/thilinarmtb/parRSB.py.git
cd parRSB.py
CC=mpicc GSLIB_DIR=../gslib/install PARRSB_DIR=../parRSB/install make
```
