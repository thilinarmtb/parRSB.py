cimport cython
cimport mpi4py.MPI as MPI
cimport numpy as cnp
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


def conn_mesh(cnp.ndarray[cnp.float64_t, ndim=2] coord,
              cnp.ndarray[cnp.float64_t, ndim=2] pinfo,
              double tol, MPI.Comm comm):
    cdef unsigned ndof = coord.shape[0]
    cdef unsigned ndim = coord.shape[1]
    cdef int npi = pinfo.shape[0]

    # sanity checks: only 3d meshes are supported as of now.
    assert ndim == 3
    assert pinfo.shape[1] == 2

    cdef unsigned nv = 8
    cdef unsigned nel = ndof // nv

    cdef double *coord_ = <double *>malloc(ndof * ndim * cython.sizeof(cython.double))
    for e in range(ndof):
        for d in range(ndim):
            coord_[e * ndim + d] = coord[e, d]

    cdef long long *pi = <long long *>malloc(npi * 2 * cython.sizeof(cython.longlong))
    for p in range(npi):
        for d in range(2):
            pi[e * 2 + d] = pinfo[e, d]

    cdef long long *vtx_ = <long long *>malloc(ndof * cython.sizeof(cython.longlong))
    cdef int err = parrsb_conn_mesh(vtx_, coord_, nel, ndim, pi, npi, tol, comm.ob_mpi)

    vtx = np.zeros((nel, nv))
    if err == 0:
        for e in range(nel):
            for v in range(nv):
                vtx[e, v] = vtx_[e * nv + v]

    free(pi)
    free(coord_)
    free(vtx_)

    return vtx
