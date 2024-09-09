# ---------------------------------------------------------------------------- #
# rargs: Copy-pastable argument parser
# version: 1.0.0
# https://github.com/J-Moravec/rargs
# ---------------------------------------------------------------------------- #


#' Get a name of a script
#'
#' Get the name of the script's filename when run through Rscript
#'
#' For instance, for a script `script.r` in the `folder` folder,
#' it could be run as `Rscript folder/script.r`. In that case,
#' the `get_scriptname` returns the `script.r`.
get_scriptname = function(){
    args = commandArgs(FALSE)

    file_arg = grep("--file=", args, fixed=TRUE, value=TRUE)[1]

    # not run throught script
    if(length(file_arg) == 0)
        return(NULL)

    sub("^--file=", "", file_arg)
    }


#' Define an option
#'
#' This is a helper function to define an option
opt = function(name, short = NULL, default = NULL, flag = FALSE){
    # if name starts with --, it is a long form
    # otherwise it is a positional argument
    long = NULL
    if(startsWith(name, "--")){
        long = name
        name = substring(name, 3)
        }

    if(flag && !is.null(long))
        default = FALSE

    list("name" = name, "short" = short, "long" = long, "default" = default, "flag" = flag)
    }


#' Parse arguments
#'
#' A POSIX-compatible argument parser.
#'
#' @param args **optional** a character vector of arguments, if not provided the commnad-line
#' arguments are obtained using the `commandArgs()` function.
#' @param options a list of one or more options obtained from the `opt` helper function.
#' @return a list of parsed arguments
parse_args = function(args = NULL, options){

    split_short_form = function(x){
        f = \(y){ if(grepl("^-[^-]", y)) paste0("-", strsplit(y, "")[[1]][-1]) else y}
        lapply(x, f) |> unlist()
        }

    short_to_long = function(args, options){
        id = match(args, options$short, nomatch = 0)
        args[id != 0] = unlist(options$long[id])
        args
        }

    check_unknown = function(args, options){
        args = grep("^-", args, value = TRUE)
        opts = unlist(c(options$long, options$short))
        unknown = args[!args %in% opts]

        if(length(unknown) != 0)
            stop("Unknown arguments: ", paste0(unknown, collapse = ","))
        }

    if(is.null(args))
        args = commandArgs(TRUE)

    # add --help to options
    options = c(options, opt("--help", "-h", flag = TRUE) |> list())
    names(options) = sapply(options, getElement, "name")
    options = as.data.frame(do.call(rbind, options))
    options[] = lapply(options, setNames, rownames(options)) # fix missing names

    # remove everything after --
    dashdash = c()
    if("--" %in% args){
        dashdash_id = which(args == "--")
        dashdash = args[-seq_len(dashdash_id)]
        args = args[seq_len(dashdash_id - 1)]
        }

    args = split_short_form(args)
    args = short_to_long(args, options)
    check_unknown(args, options)

    positional = c()
    pars = options$default

    # if arguments contain help, stop parsing
    if("--help" %in% args){
        pars$help = TRUE
        return(pars)
        }

    while(length(args) > 0){
        id = match(args[1], options$long)

        if(is.na(id)){
            positional = c(positional, args[1])
            args = args[-1]
            next
            }

        if(options$flag[[id]]){
            pars[id] = TRUE
            args = args[-1]
            next
            }

        if(length(args) < 2 || args[2] %in% options$long)
            stop("Not enough arguments for ", args[1], call. = FALSE)

        pars[id] = args[2]
        args = args[-c(1:2)]
        }

    # assign positionals to named args and the rest into pars$positional
    positional = c(positional, dashdash)
    pos = lengths(options$long) == 0
    n_pos = sum(pos)
    pars[pos] = as.list(positional)[seq_len(n_pos)]

    if(n_pos < length(positional))
        pars$positional = positional[-seq_len(n_pos)]

    pars
    }
