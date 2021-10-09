library(knitr)
## knitr options
opts_chunk$set(
    ## cache = TRUE,
    tidy = FALSE,
    comment = "#",
    collapse = FALSE, ## colapsa chunks em R Markdown
    fig.width = 8,
    fig.height = 6,
    fig.align = "center",
    out.width = "90%",
    dpi = 192, ## aumentar o dpi para exibir maior.
    ## dev = "png",
    cache.path = "cache/",
    fig.path = "figures/"
    )
