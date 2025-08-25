all: parRSB
	python3 setup.py build_ext --inplace

parRSB: gslib
	$(MAKE) -C ../parRSB SHARED=1 GSLIBPATH=../gslib/build lib install

gslib:
	$(MAKE) -C ../gslib STATIC=0 SHARED=1 install

clean:
	$(RM) -rf build/ *.so src/*.c src/*.swp
