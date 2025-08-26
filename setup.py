import os

import numpy
from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup

mpi_compile_info = os.popen("mpicc -compile_info").read().strip().split(" ")
mpi_link_info = os.popen("mpicc -link_info").read().strip().split(" ")

parrsb = Extension(
    "parrsb",
    sources=["src/parrsb.pyx"],
    include_dirs=[
        "../parRSB/install/include",
        "../gslib/build/include",
        numpy.get_include(),
    ],
    libraries=["parRSB", "gs"],
    library_dirs=["../parRSB/install/lib", "../gslib/build/lib"],
    runtime_library_dirs=["../parRSB/install/lib", "../gslib/build/lib"],
    extra_compile_args=mpi_compile_info[1:],
    extra_link_args=mpi_link_info[1:],
)

setup(
    name="parrsb.py",
    version="0.1",
    description="parrsb.py - Python wrappers for parRSB",
    long_description=open("README.md", "r").read(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Other Audience",
        "Intended Audience :: Science/Research",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Topic :: Software Development :: Libraries",
    ],
    python_requires="~=3.8",
    install_requires=["Cython==0.29", "mpi4py==3.1.3"],
    extras_require={"dev": ["pytest", "ruff"]},
    url="https://github.com/thilinarmtb/parrsb.py",
    license="MIT",
    packages=find_packages(),
    ext_modules=cythonize(parrsb, language_level=3),
)
