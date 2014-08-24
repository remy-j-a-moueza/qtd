
# QTD 

Qt bindings for dmd, forked from https://bitbucket.org/qtd/repo . 

The `dmd-2.066` branch brings changes to have it compile for dmd 2.066.

Efforts have been made to get the `override` right but there are still some
deprecation warnings left.

No extensive tests have been made. Some examples use deprecated code features 
and no longer compile. 

Simply said: your mileage may vary.



## Requirements

- dmd 2.066+
- cmake
- Qt 4 libraries.

Use the `dmd-2.066` branch to get it to work. 

QTD would not compile on 32 bit linux (Ubuntu 14.04) from dmd version 2.061 to 2.065,
most probably due to a compiler bug/regression that have been fixed in the 2.066 release.


## Compilation & installation

Clone the repository:

```
git clone https://github.com/remy-j-a-moueza/qtd.git
```

Change to the directory:

```
cd qtd
```

Make a build directory and change to it:

```
mkdir builddir
cd builddir
```

Run cmake:

```
cmake ..
```

or if your builddir it outside of the QTD directory: 

```
cmake path/to/qtd
```

You now can run make. On multiple core machine, one can use the `-j` option: 

```bash
 # simple run
 make 
 
 # on a N cores machine, -jN+1 is advised. -j5 is for a 4 core machine.
 make -j5 
 
 # Setting verbose mode to get details about the compilation process.
 make VERBOSE=1 
```

Once the library has been built, you can use `make install` or 
`sudo checkinstall` 
