# rargs

`rargs` is for **Argument Parsing in Base R** with no dependencies.

This is experimental work on building up copy-pastable argument parser for R.

## Aims:

The aim is to make a small, but feature-full dependency free copy-pastable code
to allow hassle-free integration into scripts and scripts into pipelines
without installation of any additional dependencies.

* **dependencies free**
    - no need to install additional package or dependencies
* **minimal** but **feature complete**
    - implementation should be short as possible, but support wide range of behaviour
* **portable**
    - not relying or dependencies and supporting older versions of R

This allows the creation of self-contained scripts that work in computing environments
with strict installation policy. As long as sufficient version of R is supported, it will work!

Many packages for argument parsing exist, but they often require additional dependencies, sometimes even a whole different language environment, like Python or Javascript.

If you want dependency free packages, try [getopt](https://cran.r-project.org/web/packages/getopt/index.html), [argparser](https://cran.r-project.org/web/packages/argparser/index.html), or [docopt](https://cran.r-project.org/web/packages/docopt/index.html)


## Current work in progress

### v1 -- ncbi.r

Script written for downloading and flattening archive from the NCBI genome database.

**Supports:**

* short and long arguments
* concatenated short arguments (`-srk` -> `-s -r -k`)
* all arguments are flags and do not consume additional arguments

### v2 -- sm.r

Make Sample Map for `GATK GenomicsDBImport`.
The logic is only 3 lines in 150 line script but thats not the point.

**Supports:**

* short and long arguments -- but must have defined both long and short forms
* arguments can be flags or consume a single argument

Can be easily expanded to support more arguments or concatenated short forms.

Currently a weird behaviour where:

```
Rscript rm.r foo -o output bar -p '*' baz
```

produce `foo bar baz` as positional arguments.

Funky implementation of queue/stack with `pop`
