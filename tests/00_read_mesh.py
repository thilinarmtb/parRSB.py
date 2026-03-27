import numpy as np
from mpi4py import MPI
from parrsb import Mesh
import sys

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit(1)

    comm = MPI.COMM_WORLD
    m = Mesh(sys.argv[1], comm)

    assert m.num_dimensions == 3
    assert m.num_vertices == 8
    assert m.num_elements == 8 * 8 * 8
    assert m.num_periodic_faces == 6 * 8 * 8
