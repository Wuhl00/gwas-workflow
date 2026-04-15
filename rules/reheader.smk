rule reheader:
    input:
        imputed="results/qc/data.qc1.impute.vcf.gz",
        original=config["input"]["vcf"]
    output:
        vcf="results/qc/data.qc1.impute.reheader.vcf.gz",
        tbi="results/qc/data.qc1.impute.reheader.vcf.gz.tbi"
    log:
        "results/qc/logs/reheader.log"
    params:
        tmpdir=config["tmpdir"]
    threads: 1
    shell:
        r"""
        mkdir -p $(dirname {log})
        mkdir -p {params.tmpdir}

        # 从原始 VCF 提取 header
        bcftools view -h {input.original} \
          > {params.tmpdir}/original_header.txt \
          2>> {log}

        # 用原始 header 替换 imputed VCF 的 header
        bcftools reheader \
          -h {params.tmpdir}/original_header.txt \
          {input.imputed} \
          -o {output.vcf} \
          2>> {log}

        # 清理临时文件
        rm {params.tmpdir}/original_header.txt

        # 建立索引
        tabix -p vcf {output.vcf} >> {log} 2>&1
        """

