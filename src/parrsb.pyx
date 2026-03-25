cimport cython
cimport mpi4py.MPI as MPI
from libc.stdlib cimport free, malloc
from parrsb cimport parrsb_conn_mesh, parrsb_read_mesh
import numpy as np


cdef class Mesh:
    cdef unsigned nel, nv, nbcs, ndim
    cdef long long *bcs
    cdef double *coord
    cdef public MPI.Comm c

    def __cinit__(self, str name, MPI.Comm comm):
        self.c = comm.Dup()
        cdef bytes b = name.encode('utf-8') + b'\x00'
        parrsb_read_mesh(&self.nel, &self.nv, &self.coord, &self.nbcs, &self.bcs,
                         <cython.char *>b, self.c.ob_mpi)
        if self.nv != 8:
            raise RuntimeError("Only 3D meshes are supported!")
        self.ndim = 3

    def find_connectivity(self, double tol):
        cdef unsigned long ndof = <cython.ulong>self.nel * <cython.ulong>self.nv
        cdef long long *vl = <long long *>malloc(ndof * cython.sizeof(cython.longlong))

        cdef int err = parrsb_conn_mesh(vl, self.coord, self.nel, self.ndim, self.bcs,
                                        self.nbcs, tol, self.c.ob_mpi)

        arr = np.zeros((self.nel, self.nv))
        if err == 0:
            for e in range(self.nel):
                for v in range(self.nv):
                    arr[e, v] = vl[e * self.nv + v]
        free(vl)

        return arr

    def __dealloc__(self):
        free(self.bcs)
        free(self.coord)
