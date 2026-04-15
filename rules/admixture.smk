# rules/admixture.smk
# ============================================================
# 群体结构分析模块
# 包含：LD pruning → admixture 运行 → CV error 汇总 → TASSEL 格式转换
# ============================================================

rule ld_pruning:
    input:
        vcf="results/qc/data.qc2.vcf.gz"
    output:
        prune_in="results/admixture/ld.prune.in",
        prune_out="results/admixture/ld.prune.out",
        bed="results/admixture/data.ld.bed",
        bim="results/admixture/data.ld.bim",
        fam="results/admixture/data.ld.fam"
    log:
        "results/admixture/logs/ld_pruning.log"
    threads: config["threads"]["admixture"]
    shell:
        r"""
        mkdir -p $(dirname {log})
        mkdir -p results/admixture

        # Step 1: 计算 LD，生成 prune.in / prune.out
        plink \
          --vcf {input.vcf} \
          --indep-pairwise \
            {config["admixture"]["ld_window"]} \
            {config["admixture"]["ld_step"]} \
            {config["admixture"]["ld_threshold"]} \
          --out results/admixture/ld \
          --allow-extra-chr \
          --const-fid \
          >> {log} 2>&1

        # Step 2: 提取 prune.in 位点，生成 bed 文件
        plink \
          --vcf {input.vcf} \
          --make-bed \
          --extract {output.prune_in} \
          --out results/admixture/data.ld \
          --allow-extra-chr \
          --const-fid \
          >> {log} 2>&1
        """

rule admixture_run:
    input:
        bed="results/admixture/data.ld.bed"
    output:
        q="results/admixture/data.ld.{k}.Q",
        p="results/admixture/data.ld.{k}.P"
    log:
        "results/admixture/logs/admixture_k{k}.log"
    threads: config["threads"]["admixture"]
    shell:
        r"""
        mkdir -p $(dirname {log})

        cd results/admixture

        admixture \
          --cv \
          -j{threads} \
          -s {config[admixture][seed]} \
          data.ld.bed {wildcards.k} \
          > ../../{log} 2>&1
        """

rule admixture_cv:
    input:
        logs=expand(
            "results/admixture/logs/admixture_k{k}.log",
            k=range(
                config["admixture"]["k_min"],
                config["admixture"]["k_max"] + 1
            )
        )
    output:
        cv="results/admixture/CV.error.txt"
    log:
        "results/admixture/logs/admixture_cv.log"
    shell:
        r"""
        mkdir -p $(dirname {log})

        # 提取所有 K 的 CV error，整理为两列格式
        grep -h "CV error" {input.logs} \
          | awk -F'[:=()]+' '{{
              gsub(/[[:space:]]/, "", $2);
              gsub(/[[:space:]]/, "", $3);
              print $2"\t"$3
            }}' \
          | sort -n \
          > {output.cv} 2>> {log}

        echo "CV error summary saved to {output.cv}" >> {log}
        """

rule admixture_format:
    input:
        fam="results/admixture/data.ld.fam",
        q="results/admixture/data.ld.{k}.Q".format(
            k=config["admixture"]["k_best"]
        )
    output:
        tassel_q="results/admixture/tassel.Q.txt"
    log:
        "results/admixture/logs/admixture_format.log"
    shell:
        r"""
        mkdir -p $(dirname {log})

        # 提取样本名
        cut -d ' ' -f 2 {input.fam} > $TMPDIR/indv.txt

        # 生成 TASSEL 格式 Q 文件（去掉最后一列，加 header）
        paste $TMPDIR/indv.txt {input.q} \
          | awk 'BEGIN {{ OFS="\t" }}
            NR == 1 {{
              n_q = NF - 2
              print "<Covariate>"
              printf "<Trait>"
              for (i = 1; i <= n_q; i++) {{
                printf "\tQ%d", i
              }}
              print ""
            }}
            {{
              NF = NF - 1
              print $0
            }}' \
          > {output.tassel_q} 2>> {log}
        """

