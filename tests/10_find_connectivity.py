import numpy as np
from mpi4py import MPI
from parrsb import Mesh
import sys

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit(1)

    comm = MPI.COMM_WORLD
    m = Mesh(sys.argv[1], comm)

    vtx = m.find_connectivity(0.2)

    minv = comm.allreduce(np.min(vtx), op=MPI.MIN)
    maxv = comm.allreduce(np.max(vtx), op=MPI.MAX)
    assert minv == 1
    assert maxv == 36
