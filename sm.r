#' sm.r
#'
#' Make Sample Map file for GATK GenomicDBImport
get_scriptname = function(){
    args = commandArgs(FALSE)

    file_arg = grep("--file=", args, fixed=TRUE, value=TRUE)

    # not run throught script
    if(length(file_arg) == 0)
        return(NULL)

    sub("^--file=", "", file_arg)
    }


option = function(name, short, long, default = NA, flag = FALSE){
    list("name" = name, "short" = short, "long" = long, default = default, flag = flag)
    }


options = list(
    option("pattern", "-p", "--pattern"),
    option("output", "-o", "--output"),
    option("help", "-h", "--help", flag = TRUE, default = FALSE)
    )
names(options) = sapply(options, getElement, "name")
options = as.data.frame(do.call(rbind, options))


check_unknown = function(args, options){
    args = grep("^-", args, value = TRUE)
    opts = unlist(c(options$long, options$short))
    unknown = args[!args %in% opts]

    if(length(unknown) != 0)
        stop("Unknown arguments: ", paste0(unknown, collapse = ","))
    }


short_to_long = function(args, options){
    id = match(args, options$short)
    id_valid = !is.na(id)
    args[id_valid] = unlist(options$long)[id[id_valid]]
    args
    }


pop = function(x, n = 1){
    if(length(x) == 0)
        return(NULL)

    ns = seq_len(n)
    val = x[ns]
    obj = x[-ns]
    
    assign(deparse(substitute(x)), obj, envir=parent.frame())
    
    invisible(val)
    }


parse_args = function(options){
    args = commandArgs(TRUE)
    check_unknown(args, options)
    args = short_to_long(args, options)

    # This allows weird stuff, but a simple implementaiton:
    # prog.r foo --a bar -h baz
    # produce positional: foo baz
    positional = c()
    pars = options$default
    while(length(args) > 0){
        id = match(args[1], options$long)

        if(is.na(id)){
            positional = c(positional, args[1])
            pop(args)
            next
            }

        if(options$flag[[id]]){
            pars[id] = TRUE
            pop(args)
            next
            }

        if(length(args) < 2 || args[2] %in% options$long)
            stop("Not enough arguments for ", args[1], call. = FALSE)

        pars[id] = args[2]
        pop(args, 2)
        }
    pars$positional = positional

    pars
    }


usage = function(){
    prog = get_scriptname()
    blnk = strrep(" ", nchar(prog))
    cat(paste0(
        "Usage: ", prog, "[options] file ...\n",
        "Construct Sample Map file for GATK GenomicsDBImport.\n\n",
        "  -p  --pattern regexp to extract pattern from file\n",
        "  -o  --output  output Sample Map file.\n",
        "  -h  --help    display this help message and exit\n\n",
        "This script constructs the Sample Map file for GATK GenomicsDBImport.\n",
        "The file consit of a two colums: sample names and file names in a\n",
        "tab-delimited format. Script will try to guess the sample name from\n",
        "the file name. Optionally, regexp can be provided to extract the name.\n",
        "By default basename without extension is used and the tab-delimited file.\n",
        "is printed to screen.\n\n",
        "Examples:\n",
        "  Rscript ", prog, " path/foo.g.vcf path/bar.g.vcf  'foo' and 'bar' are\n",
        "          ", blnk, "                                extracted\n",
        "  Rscript ", prog, " -o myfile foo.g.vcf       outputs is saved to myfile\n",
        "  Rscript ", prog, " -p '([a-z]+)_.*' foo_bar.g.vcf 'foo' is extracted\n\n"
        ))
    }


main = function(){
    args = parse_args(options)

    if(args$help){
        usage()
        return(invisible())
        }

    if(length(args$positional) == 0)
        stop("Not enough positional arguments")

    names = if(!is.na(args$pattern)){
        sub(args$pattern, "\\1", args$positional)
        } else {
        tools::file_path_sans_ext(basename(args$positional))
        }

    file = if(!is.na(args$output)) args$output else ""
    sm = paste(names, args$positional, sep="\t")
    cat(sm, file = file, sep = "\n") 
    }


if(sys.nframe() == 0){
    main()
    }
