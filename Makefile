MPICC ?= mpicc
GSLIB_DIR ?=
PARRSB_DIR ?=

all:
	MPICC=$(MPICC) GSLIB_DIR=$(GSLIB_DIR) PARRSB_DIR=$(PARRSB_DIR) python setup.py bdist_wheel
	pip install dist/parrsb-*.whl

clean:
	$(RM) -rf build/ dist/ parrsb.egg-info src/*.c src/*.swp
