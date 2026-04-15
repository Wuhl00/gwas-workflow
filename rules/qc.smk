rule qc_stage1:
    input:
        vcf=config["input"]["vcf"]
    output:
        vcf="results/qc/data.qc1.vcf.gz",
        tbi="results/qc/data.qc1.vcf.gz.tbi"
    log:
        "results/qc/logs/qc_stage1.log"
    threads: config["threads"]["qc"]
    shell:
        r"""
        mkdir -p $(dirname {log})

        bcftools view \
          -e 'REF="." | ALT="." | ALT="*"' \
          {input.vcf} \
          -Oz \
          2>> {log} \
        | vcftools \
          --gzvcf - \
          --max-missing {config[qc][stage1][max_missing]} \
          --min-alleles 2 \
          --max-alleles 2 \
          --recode \
          --stdout \
          1> >(bgzip -@ {threads} -c > {output.vcf}) \
          2>> {log}

        tabix -p vcf {output.vcf} >> {log} 2>&1
        """

rule qc_stage2:
    input:
        vcf="results/qc/data.qc1.impute.reheader.vcf.gz"
    output:
        vcf="results/qc/data.qc2.vcf.gz",
        tbi="results/qc/data.qc2.vcf.gz.tbi"
    log:
        "results/qc/logs/qc_stage2.log"
    threads: config["threads"]["qc"]
    shell:
        r"""
        mkdir -p $(dirname {log})

        vcftools \
          --gzvcf {input.vcf} \
          --maf {config[qc][stage2][maf]} \
          --max-missing {config[qc][stage2][max_missing]} \
          --recode \
          --stdout \
          1> >(bgzip -@ {threads} -c > {output.vcf}) \
          2> {log}

        tabix -p vcf {output.vcf} >> {log} 2>&1
        """

