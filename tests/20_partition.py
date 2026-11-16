import numpy as np
from mpi4py import MPI
from parrsb import Mesh
import sys

if __name__ == "__main__":
    if len(sys.argv) == 1:
        sys.exit(1)

    comm = MPI.COMM_WORLD
    m = Mesh(sys.argv[1], comm)

    # Let parRSB.py calculate the vertices.
    part = m.partition()

    # Reuse connectivity calculated by the first partition call.
    vertices = m.vertices
    part_cached = m.partition()
    np.testing.assert_array_equal(m.vertices, vertices)
    assert part_cached.shape == part.shape

    # Preserve connectivity explicitly calculated with a custom tolerance.
    assert m.connectivity(0.05) is None
    vertices = m.vertices
    part = m.partition()
    np.testing.assert_array_equal(m.vertices, vertices)

