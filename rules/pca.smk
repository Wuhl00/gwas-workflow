# ============================================================
# PCA module
# Tool: VCF2PCACluster (standalone binary in container)
#
# Final outputs (used by workflow):
#   - results/pca/covariates.txt
#   - results/pca/scree_summary.txt
#
# Notes:
#   - covariates.txt MUST follow TASSEL phenotype format
#   - Two header rows are required:
#       1) type row: taxa / covariate
#       2) name row: Taxa / PC1..PCn
# ============================================================

rule pca:
    input:
        vcf="results/qc/data.qc2.vcf.gz"
    output:
        eigenvec="results/pca/pca.eigenvec",
        eigenval="results/pca/pca.eigenval",
        covariates="results/pca/covariates.txt",
        scree="results/pca/scree_summary.txt"
    log:
        "results/pca/logs/pca.log"
    threads: config["threads"]["pca"]
    params:
        prefix=f"results/pca/{config['pca']['out_prefix']}",
        n_pcs=config["pca"]["n_pcs"]
    shell:
        r"""
        set -euo pipefail

        mkdir -p $(dirname {log})
        mkdir -p results/pca

        ########################################################
        # 1. Run VCF2PCACluster (standalone software)
        ########################################################
        VCF2PCACluster \
          -InVCF {input.vcf} \
          -OutPut {params.prefix} \
          -Threads {threads} \
          >> {log} 2>&1

        ########################################################
        # 2. Generate covariates.txt (TASSEL phenotype format)
        #
        # eigenvec format:
        #   SampleName  Group  Cluster  PC1  PC2  PC3 ...
        #
        # covariates.txt required format:
        #
        # <Phenotype>
        # taxa    covariate    covariate ...
        # Taxa    PC1          PC2 ...
        ########################################################

        # Line 1: file type
        echo "<Covariate>" > {output.covariates}

        # Line 2: type row (taxa + covariate)
        #printf "taxa" >> {output.covariates}
        #for i in $(seq 1 {params.n_pcs}); do
        #    printf "\tcovariate" >> {output.covariates}
        #done
        #printf "\n" >> {output.covariates}

        # Line 3: column name row (Taxa + PC names)
        printf "<Trait>\t" >> {output.covariates}
        head -1 {output.eigenvec} \
          | cut -f4-$((3+{params.n_pcs})) \
          >> {output.covariates}

        # Data rows: SampleName + PC values
        tail -n +2 {output.eigenvec} \
          | awk '{{printf "%s", $1; for (i=4; i<=3+'"{params.n_pcs}"'; i++) printf "\t%s", $i; printf "\n"}}' \
          >> {output.covariates}

        ########################################################
        # 3. Generate scree_summary.txt from eigenval
        #    (PC index + eigenvalue)
        ########################################################
        #nl -w1 -s$'\t' {output.eigenval} \
        #  | head -n {params.n_pcs} \
        #  > {output.scree}
        head -n {params.n_pcs} {output.eigenval} \
            | nl -w1 -s$'\t' \
            > {output.scree}
        """

