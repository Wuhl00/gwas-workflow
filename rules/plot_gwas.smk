rule plot_gwas:
    input:
        result = "results/gwas/{model}/{trait}/{trait}_{model}_results.txt"
    output:
        man = "results/gwas/{model}/{trait}/plots/Rect_Manhtn.1.pdf",
        qq  = "results/gwas/{model}/{trait}/plots/QQplot.2.pdf"
    params:
        outdir = "results/gwas/{model}/{trait}/plots"
    log:
        "results/gwas/{model}/{trait}/plots/plot.log"
    shell:
        r"""
        set -euo pipefail

        mkdir -p {params.outdir}

        R --vanilla <<'RSCRIPT' > {log} 2>&1
        library(CMplot)

        infile <- normalizePath("{input.result}")
        outdir <- "{params.outdir}"
        model  <- "{wildcards.model}"

        setwd(outdir)

        df <- read.table(infile, header=TRUE, sep="\t", stringsAsFactors=FALSE, check.names=FALSE)

        if (model == "GLM") {{
            df <- df[, c(2, 3, 4, 6)]
        }} else if (model %in% c("MLM", "CMLM")) {{
            df <- df[, c(2, 3, 4, 7)]
        }} else {{
            stop(paste("Unknown model:", model))
        }}

        colnames(df) <- c("SNP", "Chromosome", "Position", "P")
        df <- df[!is.na(df$P) & df$P > 0, ]

        if (nrow(df) == 0) stop("No valid SNPs after filtering")

        n <- nrow(df)
        thr1 <- 0.01 / n
        thr2 <- 0.05 / n

        CMplot(
            df,
            plot.type = "m",
            LOG10 = TRUE,
            threshold = c(thr1, thr2),
            file.output=TRUE,
            file.name="1",
            file = "pdf"
        )

        CMplot(
            df,
            plot.type = "q",
            LOG10 = TRUE,
            file.name="2",
            file = "pdf",
            file.output=TRUE
        )
RSCRIPT
        """
