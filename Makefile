MPICC ?= mpicc

GSLIB_DIR=$(CURDIR)/gslib/install
PARRSB_DIR=$(CURDIR)/parRSB/install

.PHONY: gslib parrsb parrsb.py clean nuke all

all: parrsb.py

gslib:
	if [ ! -d gslib ]; then git clone https://github.com/Nek5000/gslib.git; fi
	CC=mpicc DESTDIR=$(GSLIB_DIR) make -C gslib SHARED=1 STATIC=0

parrsb: gslib
	if [ ! -d parRSB ]; then git clone https://github.com/thilinarmtb/parRSB.git -b general_graph; fi
	CC=mpicc DESTDIR=$(PARRSB_DIR) GSLIB_DIR=$(GSLIB_DIR) make -C parRSB install SHARED=1

parrsb.py: parrsb
	MPICC=$(MPICC) GSLIB_DIR=$(GSLIB_DIR) PARRSB_DIR=$(PARRSB_DIR) uv run setup.py bdist_wheel
	uv pip install dist/parrsb*.whl

clean:
	if [ -d gslib ]; then make -C gslib clean; rm -rf gslib/install; fi
	if [ -d parRSB ]; then make GSLIB_DIR=$(GSLIB_DIR) -C parRSB clean; rm -rf parRSB/install; fi
	rm -rf build/ dist/ parrsb.py.egg-info src/*.c src/*.swp

nuke: clean
	rm -rf gslib parRSB
