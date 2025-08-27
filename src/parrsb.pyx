cimport cython
cimport mpi4py.libmpi as libmpi
cimport mpi4py.MPI as MPI
cimport numpy as cnp
from libc.stdlib cimport free, malloc
from parrsb cimport parrsb_conn_mesh


import numpy as np


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
    cdef unsigned nelem = ndof // nv

    cdef double *coord_ = <double *>malloc(ndof * ndim * cython.sizeof(cython.double))
    for e in range(ndof):
        for d in range(ndim):
            coord_[e * ndim + d] = coord[e, d]

    cdef long long *pinfo_ = <long long *>malloc(npi * 2 * cython.sizeof(cython.longlong))
    for p in range(npi):
        for d in range(2):
            pinfo_[e * 2 + d] = pinfo[e, d]

    cdef long long *vtx_ = <long long *>malloc(ndof * cython.sizeof(cython.longlong))
    cdef int err = parrsb_conn_mesh(vtx_, coord_, nelem, ndim, pinfo_, npi, tol, comm.ob_mpi)

    vtx = np.zeros((nelem, nv))
    if err != 0:
        for e in range(nelem):
            for v in range(nv):
                vtx[e, v] = vtx_[e * nv + v]

    free(pinfo_)
    free(coord_)
    free(vtx_)

    return vtx
