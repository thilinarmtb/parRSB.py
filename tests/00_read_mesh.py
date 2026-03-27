import numpy as np
from mpi4py import MPI
from parrsb import Mesh
import sys

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit(1)

    comm = MPI.COMM_WORLD
    m = Mesh(sys.argv[1], comm)

    ndim = comm.allreduce(m.num_dimensions, op=MPI.MIN)
    assert ndim == 3
    ndim = comm.allreduce(m.num_dimensions, op=MPI.MAX)
    assert ndim == 3

    nv = comm.allreduce(m.num_vertices, op=MPI.MIN)
    assert nv == 8
    nv = comm.allreduce(m.num_vertices, op=MPI.MAX)
    assert nv == 8

    nel = comm.allreduce(m.num_elements, op=MPI.SUM)
    assert nel == 8 * 8 * 8

    nbcs = comm.allreduce(m.num_periodic_faces, op=MPI.SUM)
    assert nbcs == 6 * 8 * 8
