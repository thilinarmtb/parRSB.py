import numpy as np
from mpi4py import MPI
from parrsb import conn_mesh


if __name__ == "__main__":
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()

    coord = []
    if rank == 0:
        coord.append([0, 0, 0])
        coord.append([1, 0, 0])
        coord.append([1, 1, 0])
        coord.append([0, 1, 0])
        coord.append([0, 0, 1])
        coord.append([1, 0, 1])
        coord.append([1, 1, 1])
        coord.append([0, 1, 1])

    if rank == (size - 1):
        coord.append([1, 0, 0])
        coord.append([2, 0, 0])
        coord.append([2, 1, 0])
        coord.append([1, 1, 0])
        coord.append([1, 0, 1])
        coord.append([2, 0, 1])
        coord.append([2, 1, 1])
        coord.append([1, 1, 1])

    coord = np.array(coord, dtype=np.float64)
    pinfo = np.zeros((0, 2), dtype=np.float64)
    vtx = conn_mesh(coord, pinfo, 0.2, comm)
