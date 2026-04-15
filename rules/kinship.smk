rule kinship:
    input:
        vcf="results/qc/data.qc2.vcf.gz"
    output:
        kinship=f"results/kinship/{config['kinship']['out_prefix']}.txt"
    log:
        "results/kinship/logs/kinship.log"
    threads: config["threads"]["kinship"]
    shell:
        r"""
        mkdir -p $(dirname {log})
        mkdir -p results/kinship

        run_pipeline.pl \
          -Xmx{config[kinship][memory]} \
          -vcf {input.vcf} \
          -sortPositions \
          -KinshipPlugin \
            -method {config[kinship][method]} \
            -endPlugin \
          -export results/kinship/{config[kinship][out_prefix]} \
          -exportType SqrMatrix \
          >> {log} 2>&1
        """

