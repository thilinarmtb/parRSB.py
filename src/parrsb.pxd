cimport mpi4py.libmpi as libmpi


cdef extern from "parrsb.h":
    struct parrsb_options:
        pass

    ctypedef parrsb_options* parrsb_options_t
    ctypedef libmpi.MPI_Comm MPI_Comm

    # parRSB options.
    int parrsb_options_get_default(parrsb_options_t *options)

    int parrsb_options_set_partitioner(parrsb_options_t options, int partitioner);

    int parrsb_options_set_rsb_algo(parrsb_options_t options, int algo);

    int parrsb_options_copy(parrsb_options_t *dest, const parrsb_options_t src);

    void parrsb_options_print(const parrsb_options_t options);

    int parrsb_options_free(parrsb_options_t *options);

    # Partitioning related functions.
    int parrsb_part_mesh(int *part, const long long *const vtx,
                         const double *const xyz, const int *const tag,
                         const int nel, const int nv,
                         const parrsb_options_t options, MPI_Comm comm);

    int parrsb_part_graph(int *part, unsigned num_nodes, const long long *nodes,
                          const unsigned *offsets, const long long *neighbors,
                          const parrsb_options_t options, const MPI_Comm comm);

    # Calculating connectivity.
    int parrsb_conn_mesh(long long *vtx, double *coord, unsigned nel, unsigned nDim,
                         long long *periodicInfo, int nPeriodicFaces, double tol,
                         MPI_Comm comm);
