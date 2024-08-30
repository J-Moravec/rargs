# POSIX specifications:
# https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html
# Also possibly -v --version, but -v is often used for verbose
TEST_SET("(POSIX) Options -h and --help should be provided by default", {
    # also stop evaluation of parsing
    opts = list()
    TEST(parse_args("-h", opts)$help == TRUE)
    TEST(parse_args("--help", opts)$help == TRUE)
    TEST(parse_args(character(), opts)$help == FALSE)
})


TEST_SET("(POSIX) Multiple short forms can be passed as a single token", {
    # Multiple short forms can be passed as a single token
    opts = list(
        opt("--foo", "-f", flag = TRUE),
        opt("--bar", "-b", flag = TRUE)
        )

    expected = list("foo" = TRUE, "bar" = TRUE, "help" = FALSE)
    TEST(identical(parse_args("-fb", opts), expected))
    TEST(identical(parse_args("-bf", opts), expected))
})


TEST_SET("(POSIX) Options may be supplied in any order", {
    TEST(identical(parse_args(c("-f", "-b"), opts), expected))
    TEST(identical(parse_args(c("-b", "-f"), opts), expected))
    TEST(identical(parse_args(c("--foo", "--bar"), opts), expected))
    TEST(identical(parse_args(c("--bar", "--foo"), opts), expected))
    TEST(identical(parse_args(c("--foo", "-b"), opts), expected))
    TEST(identical(parse_args(c("--bar", "-f"), opts), expected))
})


TEST_SET("(POSIX) Options are optional", {
    # parse_args does not enforce mandatory options
    # this depends on the user implementation
    # for instance, by writing:
    #
    # args = parse_args(c("-f"), list("--foo", "-f"))
    # if(is.null(args$foo))
    #   stop("foo must be specified")
    #
    opts = list(
        opt("--foo", "-f", flag = TRUE),
        opt("--bar", "-b", flag = TRUE)
        )

    TEST(identical(parse_args(c("-f"), opts), list("foo" = TRUE, bar = FALSE, help = FALSE)))
    TEST(identical(parse_args(c("--foo"), opts), list("foo" = TRUE, bar = FALSE, help = FALSE)))
    TEST(identical(parse_args(c("-b"), opts), list("foo" = FALSE, bar = TRUE, help = FALSE)))
    TEST(identical(parse_args(c("--bar"), opts), list("foo" = FALSE, bar = TRUE, help = FALSE)))
})


TEST_SET("(POSIX) Arguments are options if they start with hyphen \"-\"", {
    # Arguments are options if they start with hyphen "-"
    # otherwise they are positional arguments
    opts = list(
        opt("foo"),
        opt("bar"),
        opt("--baz", "-b"),
        opt("--qux", "-q", flag = TRUE),
        opt("--quux", flag = TRUE)
        )

    expected = list(
        "foo" = "oof",
        "bar" = "rab",
        "baz" = "zab",
        "qux" = TRUE,
        "quux" = FALSE,
        "help" = FALSE
        )

    args = c("oof", "rab", "--baz", "zab", "--qux")
    TEST(identical(parse_args(args, opts), expected))
    args = c("oof", "rab", "--qux", "-b", "zab")
    TEST(identical(parse_args(args, opts), expected))
    args = c("oof", "rab", "-b", "zab", "-q")
    TEST(identical(parse_args(args, opts), expected))
})


TEST_SET("(POSIX) The argument \"--\" terminates all options", {
    # everything past -- are optional arguments
    opts = list(
        opt("foo"),
        opt("bar"),
        opt("--baz", "-b"),
        opt("--qux", "-q", flag = TRUE),
        opt("--quux", flag = TRUE)
        )

    expected = list(
        "foo" = "oof",
        "bar" = "rab",
        "baz" = "zab",
        "qux" = TRUE,
        "quux" = FALSE,
        "help" = FALSE,
        "positional" = c("a", "b", "c")
        )

    args = c("oof", "rab", "--baz", "zab", "--qux", "--", "a", "b", "c")
    TEST(identical(parse_args(args, opts), expected))
    })


TEST_SET("(POSIX) Options may be supplied multiple times", {
    # The behaviour is left to the program.
    # We chose to overwrite the arguments.
    opts = list(
        opt("--foo", "-f"),
        opt("--bar", "-b")
        )

    expected = list(
        "foo" = "oof",
        "bar" = NULL,
        "help" = FALSE
        )

    TEST(identical(parse_args(c("--foo", "oof"), opts), expected))
    TEST(identical(parse_args(c("--foo", "bar", "-f", "oof"), opts), expected))
    TEST(identical(parse_args(c("-f", "bar", "-f", "baz", "--foo", "oof"), opts), expected))
    })


# This is weird requirement and introduce ambiguity
# Consider two argument --foo and --foobar
# If this requirement would be true, there is no way to distinguish between:
# --foobar (as in --foo bar) and --foobar (as in a flag --foobar).
#
# TEST_SET("Option and its argument may not be separated with whitespace, {
#
#    })
