cimport cython
cimport mpi4py.libmpi as libmpi
cimport mpi4py.MPI as MPI
from libc.stdlib cimport free, malloc
from parrsb cimport parrsb_conn_mesh, parrsb_options_t


cdef class parRSB:
    cdef libmpi.MPI_Comm c

    def __cinit__(self, MPI.Comm comm):
        libmpi.MPI_Comm_dup(comm.ob_mpi, &self.c)

    def __dealloc__(self):
        libmpi.MPI_Comm_free(&self.c)

    def conn_mesh(self, vtx, coord, pinfo, tol):
        (ne1, nv1) = vtx.shape
        (ne2, nd1) = coord.shape
        assert ne1 == ne2
        (np1, nd2) = pinfo.shape
        assert nd2 == 2

        cdef int ne = ne1
        cdef int nv = nv1;
        cdef long long *vtx_ = <long long *>malloc(ne * nv * cython.sizeof(cython.longlong))

        cdef int nd = nd1
        cdef double *coord_ = <double *>malloc(ne * nd * cython.sizeof(cython.double))
        for e in range(ne):
            for d in range(nd):
                coord_[e * nd + d] = coord[e, d]

        cdef int np = np1;
        cdef long long *pinfo_ = <long long *>malloc(np * 2 * cython.sizeof(cython.longlong))
        for p in range(np):
            for d in range(2):
                pinfo_[e * 2 + d] = pinfo[e, d]

        cdef double tol_ = tol;

        parrsb_conn_mesh(vtx_, coord_, ne, nd, pinfo_, np, tol_, self.c)

        for e in range(ne):
            for v in range(nv):
                vtx[e, v] = vtx_[e * nv + v]

        free(pinfo_)
        free(coord_)
        free(vtx_)
