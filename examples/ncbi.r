#' ncbi.r
#'
#' Download, extract, and flatten NCBI genome archive.
#'
#' NCBI genome archive come in zip file that hides rather deep structure.
#' This structure is in most cases rather unnecesary, convoluted, and makes
#' navigating the folder rather difficult.
#'
#' This script downloads the archive, extracts it and flatten the structure,
#' preserving only required files.
#'
#' For instance, the archive GCF_900626175.2.zip contains:
#' - README.md
#' - ncbi_dataset/data/assembly_data_report.jsonl
#' - ncbi_dataset/data/GCF_900626175.2/GCF_900626175.2_cs10_genomic.fna
#' - ncbi_dataset/data/GCF_900626175.2/genomic.gff
#' - ncbi_dataset/data/GCF_900626175.2/sequence_report.jsonl
#' - ncbi_dataset/data/dataset_catalog.json
#'
#' The data and sequence report as well as dataset catalog are not required for futher analysis.
#' Only the .gff and .fna files are required.
basename_sans_ext = function(x){
    tools::file_path_sans_ext(basename(x))
    }


download = function(x, id = NULL, types = c("GENOME_FASTA", "GENOME_GTF"), overwrite = FALSE,
                    quiet = TRUE, timeout = 3600){

    if(is.null(id)){
        id = basename_sans_ext(x)
        }

    if(file.exists(x) && !overwrite)
        return(invisible())

    formats = c("GENOME_FASTA", "GENOME_GFF", "GENOME_GTF", "RNA_FASTA",
                "CDS_FASTA", "PROT_FASTA", "SEQUENCE_REPORT")
    types = match.arg(types, formats, several.ok = TRUE)

    base = "https://api.ncbi.nlm.nih.gov/datasets/v2alpha/genome/accession/"
    types = paste0(types, collapse=",")

    url = paste0(
        base,
        id, "/download?include_annotation_type=",
        types
        )

    op = options("timeout" = timeout)
    err = download.file(url, x, quiet = quiet)
    options(op)

    if(err != 0){
        file.remove(x)
        stop(paste0("Download of '", id, "' from NCBI failed."))
        }

    # If invalid ID is provided, the download progresses normally but the file is malformed.
    # The usual size of such file seems to be 855 bytes.
    if(file.size(x) < 1000){
        file.remove(x)
        stop(paste0("The requested ID '", id, "' doesn't exist."))
        }

    invisible()
    }


extract = function(x, local = FALSE){
    ext = tools::file_ext(x)
    prefix = basename_sans_ext(x)

    if(ext != "zip")
        stop(paste0("Unrecognised extension '", ext, "'. Only zip archives are supported.")) 

    workdir = file.path(if(local) dirname(x) else tempdir(), prefix)
    unzip(x, exdir = workdir, unzip = "unzip")
    }


flatten = function(x, local = FALSE, clean = TRUE){
    prefix = basename_sans_ext(x)

    workdir = file.path(if(local) dirname(x) else tempdir(), prefix)
    files = file.path(workdir, unzip(x, list = TRUE)$Name)

    lapply(files, move, dir = dirname(x), prefix = prefix)

    if(clean)
        unlink(workdir, recursive = TRUE, force = TRUE)

    invisible()
    }


"%nin%" = Negate("%in%")


move = function(x, dir, prefix){
    ext = tools::file_ext(x)

    if(ext %nin% c("fna", "gtf"))
        return()

    new_path = file.path(dir, paste0(prefix, ".", ext))
    file.copy(x, new_path)
    }


get_scriptname = function(){
    args = commandArgs(FALSE)

    file_arg = grep("--file=", args, fixed=TRUE, value=TRUE)

    # not run throught script
    if(length(file_arg) == 0)
        return(NULL)

    sub("^--file=", "", file_arg)
    }


usage = function(){
    prog = get_scriptname()
    blnk = strrep(" ", nchar(prog))
    cat(paste0(
        "Usage: ", prog, " [options] file.zip\n",
        "Download, extract, and flatten NCBI genome archive.\n\n",
        "  -d,  --download  download genomic archive from NCBI\n",
        "  -o,  --overwrite overwrite archive if it exists\n",
        "  -e,  --extract   extract genomic archive\n",
        "  -l,  --locally   extract the archive locally\n",
        "  -f,  --flatten   flatten the extracted archive\n",
        "  -h,  --help      display this help and exit\n",
        "\n",
        "The option can be specified in the POSIX-like format. Both long and\n",
        "short options are allowed. By default, ", prog, " downloads, extracts,\n",
        "and flattens the specified archive. When any argument is specified,\n",
        "this behaviour is suppressed. This is useful when the archive is already\n",
        "downloaded.\n\n",
        "The file must be in the format [NCBI ID].zip, where [NCBI ID] is the ID\n",
        "of the genome that will be downloaded from NCBI genome website, see:\n",
        "https://www.ncbi.nlm.nih.gov/datasets/genome/ for more information.\n\n",
        "If the '-el' options are specified, the archive is extracted into the\n",
        "archive's directory. To flatten this extracted archive, '-fl' needs\n",
        "to be specified.\n\n",
        "Examples:\n",
        "  Rscript ", prog, " file.zip       downloads, extracts, and flattens\n",
        "  Rscript ", prog, " -ref file.zip  equivalent to above\n",
        "  Rscript ", prog, " -ef file.zip   only extract and flattens\n",
        "  Rscript ", prog, " -el file.zip   archive is extracted to a local path\n",
        "  Rscript ", prog, " -e  file.zip   archive is extracted to a temp path,\n",
        "          ", blnk, "                this path is deleted when R session\n",
        "          ", blnk, "                ends, so no output is produced.\n\n"
        ))
    }


option = function(name, short = NULL, long = NULL, positional = NULL, default = FALSE){
    list("name" = name, "short" = short, "long" = long,
         positional = positional, default = default)
    }


getr = function(x, y, list = FALSE){
    z = sapply(x, getElement, y, simplify = FALSE)
    if(list) z else unlist(z)
    }


options = list(
    option("download", "-d", "--download"),
    option("extract", "-e", "--extract"),
    option("flatten", "-f", "--flatten"),
    option("local", "-l", "--locally"),
    option("overwrite", "-o", "--overwrite"),
    option("help", "-h", "--help"),
    option("file", positional = TRUE, default = character())
    )
names(options) = getr(options, "name")


split_short_form = function(x){
    paste0("-", strsplit(x, "")[[1]][-1])
    }


preprocess_args = function(args){

    # split short forms
    id = grep("^-[^-]", args)
    short = unlist(lapply(args[id], split_short_form))
    if(length(id) > 0) args = args[-id]

    # get long args
    id = grep("^--", args)
    long = args[id]
    if(length(id) > 0) args = args[-id]

    # everything else is assumed to be positional
    positional = args

    list("short" = short, "long" = long, "positional" = positional)
    }


parse_args = function(options){
    args = commandArgs(TRUE)
    args = preprocess_args(args)

    opts = getr(options, "default", list = TRUE)
    opts_short = getr(options, "short")
    opts_long = getr(options, "long")
    unknown = setdiff(c(args$short, args$long), c(opts_short, opts_long))
    if(length(unknown) > 1)
        stop("Unknown arguments: ", paste0(unknown, collapse = ","))

    opts[names(opts_short)[opts_short %in% args$short]] = TRUE
    opts[names(opts_long)[opts_long %in% args$long]] = TRUE

    opts_positional = names(getr(options, "positional"))
    opts[[opts_positional]] = args$positional

    opts
    }

main = function(){
    args = parse_args(options)

    if(args$help){
        usage()
        return(invisible())
        }

    if(length(args$file) < 1)
        stop("Not enough arguments.", call. = FALSE)

    if(length(args$file) > 1)
        stop("Too many argument.", call. = FALSE)

    if(tools::file_ext(args$file) != "zip")
        stop(paste0("Unrecognised extension '", ext, "'. Only zip archives are supported.")) 

    # implement requested default behaviour
    default = c("download", "extract", "flatten")
    if(all(unlist(args[default]) == FALSE)) args[default] = TRUE

    if(args$download)
        download(args$file, overwrite = args$overwrite)

    if(args$extract)
        extract(args$file, args$local)

    if(args$flatten)
        flatten(args$file, args$local)
    }


if(sys.nframe() == 0){
    main()
    }
