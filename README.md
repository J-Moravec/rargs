# rargs

`rargs` for **Argument Parsing in Base R** for

## Features

`rargs` aims to be a small, but feature-full dependency free copy-pastable code
to allow hassle-free integration into scripts and scripts into pipelines
without installation of any dependencies (beside R itself).

`rargs` is:

* **dependencies free** - no need to install additional package or dependencies
* **minimal** but **feature complete**
    - implementation should be short as possible, but supports wide range of behaviour
* **portable**
    - not relying or dependencies, latest base R features, or system specific behaviour
* (mostly) **POSIX compatible**
    - implements the common standard
* **unit-tested** -- while lack of bugs cannot be guranteed, a number of unit-tests were written using the [mutr](https://github.com/J-Moravec/mutr) framework.

This allows the creation of self-contained scripts that work in computing environments
with strict installation policy. As long as sufficient version of R is supported, it will work!

Many packages for argument parsing exist, but they often require additional dependencies, sometimes even a whole different language environment, like Python or Javascript.

If you want dependency free packages, try [getopt](https://cran.r-project.org/web/packages/getopt/index.html), [argparser](https://cran.r-project.org/web/packages/argparser/index.html), or [docopt](https://cran.r-project.org/web/packages/docopt/index.html).

If you want to get rid of dependencies entirely, `rargs` is here for you.

## Installation

Simply copy the content of `rargs.r` into your script, it is that simple!

## Usage

First, define options using the `opt` helper. For instance

```
opts = list(
    opt("foo"),
    opt("--bar"),
    opt("--baz", "-b", flag = TRUE)
    )
```

define a positional argument `foo`, optional argument `bar`,
and a flag `baz` that can be also specified using short form `-b`.

Then use `parse_args(options = opts)`, which will call `commandArgs(TRUE)` and return a list with parsed arguments.

Alternatively, if you want to preprocess your arguments, or obtain them from a different source,
you can type `parse_args(args, opts)`.

For instance, if `args = c("oof", "-b", "--bar", "rab")`, `parse_args` will return

```
list(
    "foo" = "oof",
    "bar" = "rab",
    "baz" = TRUE,
    "help" = FALSE
    )
```

It is up to the developer to process these arguments.

### Help

If `-h` or `--help` is in the arguments, `parse_args` will have an early exit after setting `help = TRUE`. The developer should likely implement a `usage()` function and print in when `help = TRUE`.

### Mandatory options

No option is assumed to be mandatory, this can be enforced by user, for intance if `--foo` is mandatory, simply write:

```
args = parse_args(opts)
if(is.null(args$foo))
    stop("--foo is required parameter")
```


### Positional arguments

One strang, but POSIX compatible behaviour is that positional arguments can be interspaced between the optional. For instance, if `--foo` is a flag and `--baz` an optional argument, then
`--foo one --baz two three` will have three positional arguments `one`, `two` and `three`.

`rargs` support both named and unnamed positional arguments.
Named positional arguments are specfied as above where

```
opts = list(
    opt("foo"),
    opt("bar"
    )
```

specifies two named positional arguments `foo` and `bar` that will be assigned first two positional arguments that were parsed or `NULL` if there was not enough parsed positional arguments.

All other parsed arguments are returned as `positional` from `parse_args`. For instance `paste_args(c("f", "b", "z", "q"), opts)` will return:

```
list(
    "foo" = f,
    "bar" = b,
    "help = FALSE, # help is always added
    "positional" = c("z", "q")
    )
```

### Dashdahs `--`

As per POSIX, anything after `--` is a positional argument.
For instance, if `args = c("--", "--foo", "--bar")`, the positional arguments will be `--foo` and `--bar`, even though they start with `-`.

## Examples

* [ncbi.r](https://github.com/J-Moravec/ncbi.r) a dependency-free script to download reference genomes from NCBI
