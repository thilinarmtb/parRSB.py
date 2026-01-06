MPICC ?= mpicc
GSLIB_DIR ?= ../gslib/install
PARRSB_DIR ?= ../parRSB/install

all:
	MPICC=$(MPICC) GSLIB_DIR=$(GSLIB_DIR) PARRSB_DIR=$(PARRSB_DIR) uv run setup.py bdist_wheel
	uv pip install dist/parrsb*.whl

clean:
	rm -rf build/ dist/ parrsb.py.egg-info src/*.c src/*.swp
