cimport cython
cimport mpi4py.libmpi as libmpi
cimport mpi4py.MPI as MPI
cimport numpy as np
from libc.stdlib cimport free, malloc
from parrsb cimport parrsb_conn_mesh


def conn_mesh(np.ndarray[np.float64_t, ndim=2] coord,
              np.ndarray[np.float64_t, ndim=2] pinfo,
              double tol, MPI.Comm comm):
    cdef int nev = coord.shape[0]
    cdef int nd = coord.shape[1]
    cdef int np = pinfo.shape[0]

    # sanity checks: only 3d meshes are supported as of now.
    assert nd == 3
    assert pinfo.shape[1] == 2

    cdef int nv = 8
    cdef int ne = nev // nv

    cdef double *coord_ = <double *>malloc(ne * nd * cython.sizeof(cython.double))
    for e in range(ne):
        for d in range(nd):
            coord_[e * nd + d] = coord[e, d]

    cdef long long *pinfo_ = <long long *>malloc(np * 2 * cython.sizeof(cython.longlong))
    for p in range(np):
        for d in range(2):
            pinfo_[e * 2 + d] = pinfo[e, d]

    cdef long long *vtx_ = <long long *>malloc(ne * nv * cython.sizeof(cython.longlong))
    cdef int err = parrsb_conn_mesh(vtx_, coord_, ne, nd, pinfo_, np, tol, comm.ob_mpi)

    vtx = np.zeros((ne, nv))
    if err != 0:
        for e in range(ne):
            for v in range(nv):
                vtx[e, v] = vtx_[e * nv + v]

    free(pinfo_)
    free(coord_)
    free(vtx_)

    return vtx
