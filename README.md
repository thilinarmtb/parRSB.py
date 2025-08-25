## Python wrappers for parRSB

### Building the library

First we need to clone `gslib`, `parRSB` and `parRSB.py`:

```
git clone https://github.com/Nek5000/gslib.git
git clone https://github.com/thilinarmtb/parRSB.git -b general_graph
git clone https://github.com/thilinarmtb/parRSB.py.git
```

Then build the wrappers:
```
cd parRSB.py
CC=mpicc make
```
