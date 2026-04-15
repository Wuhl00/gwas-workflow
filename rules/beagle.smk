rule beagle_impute:
    input:
        vcf="results/qc/data.qc1.vcf.gz"
    output:
        vcf="results/qc/data.qc1.impute.vcf.gz",
        tbi="results/qc/data.qc1.impute.vcf.gz.tbi"
    log:
        "results/qc/logs/beagle_impute.log"
    threads: config["beagle"]["nthreads"]
    params:
        jar=config["beagle"]["jar"],
        memory=config["beagle"]["memory"]
    shell:
        r"""
        mkdir -p $(dirname {log})

        java \
          -Xmx{params.memory} \
          -jar {params.jar} \
          gt={input.vcf} \
          out=results/qc/data.qc1.impute \
          nthreads={threads} \
          > {log} 2>&1

        tabix -p vcf {output.vcf} >> {log} 2>&1
        """

