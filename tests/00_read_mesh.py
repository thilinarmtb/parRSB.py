import numpy as np
from mpi4py import MPI
from parrsb import Mesh
import sys

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit(1)

    comm = MPI.COMM_WORLD
    m = Mesh(sys.argv[1], comm)

    assert m.nv == 8
    sys.exit(0)
