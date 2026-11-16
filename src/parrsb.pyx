cimport cython
cimport mpi4py.MPI as MPI

from libc.stddef cimport size_t
from libc.stdlib cimport free, malloc
from libc.string cimport memcpy
from parrsb cimport parrsb_conn_mesh, parrsb_read_mesh

import numpy as np


cdef void *_checked_malloc(size_t item_size, size_t count) except *:
    cdef void *ptr
    cdef size_t max_size = <size_t>-1

    if count == 0:
        return NULL

    if item_size == 0:
        raise ValueError("item_size must be positive")

    if count > max_size // item_size:
        raise OverflowError("Requested allocation is too large")

    ptr = malloc(count * item_size)

    if ptr == NULL:
        raise MemoryError("Could not allocate memory")

    return ptr


cdef class Options:
    cdef parrsb_options_t opts

    def __cinit__(self):
        parrsb_options_get_default(&self.opts)

    def partitioner(self, int partitioner):
        parrsb_options_set_partitioner(self.opts, partitioner)

    def __dealloc__(self):
        parrsb_options_free(&self.opts)


cdef class Mesh:
    cdef unsigned nel, nv, nbcs, ndim
    cdef long long *bcs
    cdef long long *vl
    cdef double *coord
    cdef public MPI.Comm c

    def __cinit__(self, *args, **kwargs):
        """Initialize safe defaults for either construction path."""
        self.nel = 0
        self.nv = 0
        self.nbcs = 0
        self.ndim = 0

        self.bcs = NULL
        self.vl = NULL
        self.coord = NULL
        self.c = None

    def __init__(self, str name, MPI.Comm comm not None):
        """Read a mesh from a file using its filename prefix."""
        cdef bytes filename
        cdef int err

        if self.c is not None:
            raise RuntimeError("Mesh is already initialized")

        self.c = comm.Dup()
        filename = name.encode("utf-8") + b"\x00"

        err = parrsb_read_mesh(
            &self.nel,
            &self.nv,
            &self.coord,
            &self.nbcs,
            &self.bcs,
            <cython.char *>filename,
            self.c.ob_mpi,
        )

        if err != 0:
            raise RuntimeError(
                f"parrsb_read_mesh() failed with error = {err}"
            )

        if self.nv != 8:
            raise RuntimeError("Only 3D meshes are supported!")

        self.ndim = 3
        self.vl = <long long *>_checked_malloc(
            cython.sizeof(cython.longlong),
            int(self.nel) * int(self.nv),
        )

    @staticmethod
    def from_arrays(
        coord,
        MPI.Comm comm not None,
        bcs=None,
    ):
        """Construct a mesh from this rank's local arrays.

        Parameters
        ----------
        coord : array-like, shape (nel, 8, 3)
            Coordinates in native parRSB vertex order.
        comm : mpi4py.MPI.Comm
            Communicator shared by the distributed mesh.
        bcs : integer array-like, shape (nbcs, 4), optional
            Periodic records containing element ID, face ID,
            paired element ID, and paired face ID, using native
            parRSB numbering. None means no periodic records.

        Mesh sizes are inferred from the array shapes. Only 3D
        meshes with eight vertices per element are supported.
        Input arrays are copied into Mesh-owned buffers.
        All ranks in comm must participate in construction.
        """
        cdef Mesh mesh
        cdef const double[:, :, ::1] coord_view
        cdef const long long[:, ::1] bcs_view
        cdef size_t coord_nbytes
        cdef size_t bcs_nbytes

        coord_array = np.ascontiguousarray(
            coord,
            dtype=np.float64,
        )

        if coord_array.ndim != 3:
            raise ValueError("coord must have shape (nel, nv, ndim)")

        nel, nv, ndim = coord_array.shape

        if ndim != 3:
            raise ValueError("Only ndim=3 is supported")

        if nv != 8:
            raise ValueError(
                "coord must have eight vertices per element for ndim=3"
            )

        if not np.isfinite(coord_array).all():
            raise ValueError("coord must contain only finite values")

        bcs_array = (
            np.empty((0, 4), dtype=np.longlong)
            if bcs is None else np.asarray(bcs)
        )

        if bcs_array.ndim != 2 or bcs_array.shape[1] != 4:
            raise ValueError(
                "bcs must have shape (nbcs, 4)"
            )

        nbcs = bcs_array.shape[0]

        if bcs_array.size:
            if bcs_array.dtype.kind not in ("i", "u"):
                raise TypeError("bcs must contain integers")

            limits = np.iinfo(np.longlong)

            if (
                int(bcs_array.min()) < limits.min
                or int(bcs_array.max()) > limits.max
            ):
                raise OverflowError(
                    "bcs values must fit in C long long"
                )

        bcs_array = np.ascontiguousarray(
            bcs_array,
            dtype=np.longlong,
        )

        coord_view = coord_array
        bcs_view = bcs_array

        coord_nbytes = coord_array.nbytes
        bcs_nbytes = bcs_array.nbytes

        # Runs __cinit__, but skips the file-loading __init__.
        mesh = Mesh.__new__(Mesh)

        # Cython checks conversion into the unsigned fields.
        mesh.nel = nel
        mesh.nv = nv
        mesh.ndim = ndim
        mesh.nbcs = nbcs

        if coord_nbytes != 0:
            mesh.coord = <double *>malloc(coord_nbytes)

            if mesh.coord == NULL:
                raise MemoryError(
                    "Could not allocate mesh coordinates"
                )

            memcpy(
                mesh.coord,
                &coord_view[0, 0, 0],
                coord_nbytes,
            )

        if bcs_nbytes != 0:
            mesh.bcs = <long long *>malloc(bcs_nbytes)

            if mesh.bcs == NULL:
                raise MemoryError(
                    "Could not allocate periodic faces"
                )

            memcpy(
                mesh.bcs,
                &bcs_view[0, 0],
                bcs_nbytes,
            )

        mesh.vl = <long long *>_checked_malloc(
            cython.sizeof(cython.longlong),
            int(mesh.nel) * int(mesh.nv),
        )
        mesh.c = comm.Dup()

        return mesh

    cdef _parrsb_conn_mesh(self, double tol=0.2):
        return parrsb_conn_mesh(
            self.vl,
            self.coord,
            self.nel,
            self.ndim,
            self.bcs,
            self.nbcs,
            tol,
            self.c.ob_mpi,
        )

    def partition(self, long long[:, :] vtx=None, Options opts=None):
        cdef long long[:, :] vtx_
        cdef long long *vl_
        cdef int err

        if vtx is None:
            err = self._parrsb_conn_mesh()

            if err != 0:
                raise RuntimeError(
                    f"parrsb_conn_mesh() failed with error = {err}"
                )

            vl_ = self.vl
        else:
            if vtx.shape[0] != self.nel or vtx.shape[1] != self.nv:
                raise ValueError(
                    f"vtx must have shape {(self.nel, self.nv)}"
                )

            vtx_ = np.ascontiguousarray(vtx)
            vl_ = NULL

            if self.nel != 0:
                vl_ = &vtx_[0, 0]

        opts_ = Options() if opts is None else opts

        cdef size_t part_nbytes = (
            int(self.nel) * cython.sizeof(cython.int)
        )
        cdef int *part = NULL

        if part_nbytes != 0:
            part = <int *>malloc(part_nbytes)

            if part == NULL:
                raise MemoryError("Could not allocate partition output")

        try:
            err = parrsb_part_mesh(
                part,
                vl_,
                self.coord,
                self.nel,
                self.nv,
                opts_.opts,
                self.c.ob_mpi,
            )

            if err != 0:
                raise RuntimeError(
                    f"parrsb_part_mesh() failed with error = {err}"
                )

            arr = np.zeros(self.nel, dtype=np.int32)

            for e in range(self.nel):
                arr[e] = part[e]

            return arr
        finally:
            free(part)

    def connectivity(self, double tol):
        cdef int err = self._parrsb_conn_mesh(tol)

        if err != 0:
            raise RuntimeError(
                f"parrsb_conn_mesh() failed with error = {err}"
            )

        arr = np.zeros(
            (self.nel, self.nv),
            dtype=np.int64,
        )

        for e in range(self.nel):
            for v in range(self.nv):
                arr[e, v] = self.vl[e * self.nv + v]

        return arr

    @property
    def coordinates(self):
        """Return a copy of coordinates with shape (nel, nv, ndim)."""
        cdef double[:, :, ::1] view
        cdef size_t nbytes

        arr = np.empty(
            (self.nel, self.nv, self.ndim),
            dtype=np.float64,
        )

        view = arr
        nbytes = arr.nbytes

        if nbytes != 0:
            memcpy(
                &view[0, 0, 0],
                self.coord,
                nbytes,
            )

        return arr

    @property
    def periodic_faces(self):
        """Return a copy of periodic records with shape (nbcs, 4)."""
        cdef long long[:, ::1] view
        cdef size_t nbytes

        arr = np.empty(
            (self.nbcs, 4),
            dtype=np.longlong,
        )

        view = arr
        nbytes = arr.nbytes

        if nbytes != 0:
            memcpy(
                &view[0, 0],
                self.bcs,
                nbytes,
            )

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

