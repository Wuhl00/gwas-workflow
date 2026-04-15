def get_covar(wildcards):
    if config["admixture"]["enabled"]:
        return "results/admixture/tassel.Q.txt"
    return "results/pca/covariates.txt"

rule gwas:
    input:
        vcf="results/qc/data.qc2.vcf.gz",
        pheno="results/phenotype/traits/{trait}.txt",
        covar=get_covar,
        kinship="results/kinship/kinship.txt"
    output:
        "results/gwas/{model}/{trait}/{trait}_{model}_results.txt"
    log:
        "results/gwas/{model}/{trait}/logs/gwas.log"
    params:
        outdir="results/gwas/{model}/{trait}"
    wildcard_constraints:
        model="GLM|MLM|CMLM"
    shell:
        r"""
        mkdir -p $(dirname {log})
        mkdir -p {params.outdir}
        echo "Pheno input: {input.pheno}" >> {log}
        tmpvcf=$(mktemp --suffic=.vcf)
        gunzip -c {input.vcf} > $tmpvcf

        if [ "{wildcards.model}" == "GLM" ]; then
            run_pipeline.pl \
              -Xms{config[gwas][memory_min]} \
              -Xmx{config[gwas][memory_max]} \
              -fork1 -vcf $tmpvcf \
              -fork2 -t {input.pheno} \
              -fork3 -q {input.covar} \
              -combine4 -input1 -input2 -input3 -intersect \
              -FixedEffectLMPlugin -endPlugin \
              -export {params.outdir}/{wildcards.trait}_{wildcards.model} \
              -runfork1 -runfork2 -runfork3 \
              >> {log} 2>&1
            
            # GLM site stats are in file 1
            mv {params.outdir}/{wildcards.trait}_{wildcards.model}1.txt {output}
            # Rename allele effects for clarity (if generated)
            mv {params.outdir}/{wildcards.trait}_{wildcards.model}2.txt {params.outdir}/{wildcards.trait}_{wildcards.model}_allele_effects.txt 2>/dev/null || true

        elif [ "{wildcards.model}" == "MLM" ]; then
            run_pipeline.pl \
              -Xms{config[gwas][memory_min]} \
              -Xmx{config[gwas][memory_max]} \
              -fork1 -vcf $tmpvcf \
              -fork2 -t {input.pheno} \
              -fork3 -q {input.covar} \
              -fork4 -k {input.kinship} \
              -combine5 -input1 -input2 -input3 -intersect \
              -combine6 -input5 -input4 -mlm \
              -mlmVarCompEst P3D \
              -mlmCompressionLevel None \
              -export {params.outdir}/{wildcards.trait}_{wildcards.model} \
              -exportType Text \
              -runfork1 -runfork2 -runfork3 -runfork4 \
              >> {log} 2>&1
            
            # MLM site stats are in file 2, model stats in file 1
            mv {params.outdir}/{wildcards.trait}_{wildcards.model}2.txt {output}
            mv {params.outdir}/{wildcards.trait}_{wildcards.model}1.txt {params.outdir}/{wildcards.trait}_{wildcards.model}_model_stats.txt 2>/dev/null || true

        elif [ "{wildcards.model}" == "CMLM" ]; then
            run_pipeline.pl \
              -Xms{config[gwas][memory_min]} \
              -Xmx{config[gwas][memory_max]} \
              -fork1 -vcf $tmpvcf \
              -fork2 -t {input.pheno} \
              -fork3 -q {input.covar} \
              -fork4 -k {input.kinship} \
              -combine5 -input1 -input2 -input3 -intersect \
              -combine6 -input5 -input4 -mlm \
              -mlmVarCompEst P3D \
              -mlmCompressionLevel Optimum \
              -export {params.outdir}/{wildcards.trait}_{wildcards.model} \
              -exportType Text \
              -runfork1 -runfork2 -runfork3 -runfork4 \
              >> {log} 2>&1
            
            # CMLM site stats are in file 2, model stats in file 1
            mv {params.outdir}/{wildcards.trait}_{wildcards.model}2.txt {output}
            mv {params.outdir}/{wildcards.trait}_{wildcards.model}1.txt {params.outdir}/{wildcards.trait}_{wildcards.model}_model_stats.txt 2>/dev/null || true
        fi

        rm -f $tmpvcf
        """

