all: parRSB
	python setup.py build_ext
	python setup.py install

parRSB: gslib
	$(MAKE) -C ../parRSB SHARED=1 GSLIBPATH=../gslib/build lib install

gslib:
	$(MAKE) -C ../gslib STATIC=0 SHARED=1 install

clean:
	$(RM) -rf build/ *.so src/*.c src/*.swp

nuke: clean
	$(MAKE) -C ../parRSB GSLIBPATH=../gslib/build clean
	$(MAKE) -C ../gslib clean
