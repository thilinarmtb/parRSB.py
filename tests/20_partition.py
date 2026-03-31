import numpy as np
from mpi4py import MPI
from parrsb import Mesh
import sys

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit(1)

    comm = MPI.COMM_WORLD
    m = Mesh(sys.argv[1], comm)

    # Let parRSB.py calculate the vertices.
    part = m.partition()

    # Use vertices already calculated.
    vtx = m.connectivity(0.2)
    part = m.partition(vtx)
