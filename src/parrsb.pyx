cimport cython
cimport mpi4py.MPI as MPI
from libc.stdlib cimport free, malloc
from parrsb cimport parrsb_conn_mesh, parrsb_read_mesh
import numpy as np


cdef class Options:
    cdef parrsb_options_t opts

    def __cinit__(self):
        parrsb_options_get_default(&self.opts)

    def set_partitioner(self, int partitioner):
        parrsb_options_set_partitioner(self.opts, partitioner)

    def set_rsb_algo(self, int rsb_algo):
        parrsb_options_set_rsb_algo(self.opts, rsb_algo)

    def __dealloc__(self):
        parrsb_options_free(&self.opts)


cdef class Mesh:
    cdef unsigned nel, nv, nbcs, ndim
    cdef long long *bcs
    cdef long long *vl
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

        cdef unsigned long ndof = <cython.ulong>self.nel * <cython.ulong>self.nv
        self.vl = <long long *>malloc(ndof * cython.sizeof(cython.longlong))

    cdef _parrsb_conn_mesh(self, double tol=0.2):
        return parrsb_conn_mesh(self.vl, self.coord, self.nel, self.ndim, self.bcs,
                                self.nbcs, tol, self.c.ob_mpi)

    def find_connectivity(self, double tol):
        cdef int err = self._parrsb_conn_mesh(tol)

        arr = np.zeros((self.nel, self.nv), dtype=int)
        if err == 0:
            for e in range(self.nel):
                for v in range(self.nv):
                    arr[e, v] = self.vl[e * self.nv + v]
        return arr

    @property
    def num_vertices(self):
        return self.nv

    @property
    def num_elements(self):
        return self.nel

    @property
    def num_dimensions(self):
        return self.ndim

    @property
    def num_periodic_faces(self):
        return self.nbcs

    def __dealloc__(self):
        free(self.bcs)
        free(self.coord)
        free(self.vl)
