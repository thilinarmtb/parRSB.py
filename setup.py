import os

import numpy
from Cython.Build import cythonize
from setuptools import Extension, find_packages, setup
from pathlib import Path

try:
    mpicc = os.environ["MPICC"]
except KeyError:
    print("MPICC is not set!")
try:
    parrsb_dir = os.environ["PARRSB_DIR"]
except KeyError:
    print("PARRSB_DIR is not set!")
try:
    gslib_dir = os.environ["GSLIB_DIR"]
except KeyError:
    print("GSLIB_DIR is not set!")

mpi_compile_info = os.popen(f"{mpicc} -compile_info").read().strip().split(" ")
mpi_link_info = os.popen(f"{mpicc} -link_info").read().strip().split(" ")
parrsb_path = Path(parrsb_dir)
gslib_path = Path(gslib_dir)

resolve = lambda path: str(path.resolve())
parrsb = Extension(
    "parrsb",
    sources=["src/parrsb.pyx"],
    include_dirs=[
        numpy.get_include(),
        resolve(parrsb_path / "include"),
        resolve(gslib_path / "include"),
    ],
    libraries=["parRSB", "gs"],
    library_dirs=[resolve(parrsb_path / "lib"), resolve(gslib_path / "lib")],
    runtime_library_dirs=[resolve(parrsb_path / "lib"), resolve(gslib_path / "lib")],
    extra_compile_args=mpi_compile_info[1:],
    extra_link_args=mpi_link_info[1:],
)


setup(
    name="parrsb",
    version="0.1",
    description="parrsb.py - Python wrappers for parRSB",
    long_description=open("README.md", "r").read(),
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Other Audience",
        "Intended Audience :: Science/Research",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Topic :: Software Development :: Libraries",
    ],
    setup_requires=["cython>=0.29.24", "setuptools", "numpy", "mpi4py"],
    python_requires=">=3.9,<4",
    url="https://github.com/thilinarmtb/parrsb.py",
    license="MIT",
    packages=[],
    ext_modules=cythonize(parrsb, language_level=3),
)
