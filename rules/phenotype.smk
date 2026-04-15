rule split_phenotype:
    input:
        pheno=config["phenotype"]["input"]
    output:
        trait_list="results/phenotype/trait_list.txt",
        phenos=expand(
            "results/phenotype/traits/{trait}.txt",
            trait=TRAITS
        )
    log:
        "results/phenotype/logs/split_phenotype.log"
    shell:
        r"""
        mkdir -p $(dirname {log})
        mkdir -p results/phenotype/traits

        # 保存 trait 名称列表
        head -1 {input.pheno} \
          | cut -f2- \
          | tr '\t' '\n' \
          > {output.trait_list}

        # 一步到位拆分为 TASSEL 可读表型文件
        awk -F'\t' '
        FNR == 1 {{
            for (i = 2; i <= NF; i++) {{
                colnames[i] = $i
                filename = "results/phenotype/traits/" $i ".txt"
                # print "<Phenotype>" > filename
                # print "taxa\tdata" >> filename
                print "<Trait>\t" $i >> filename
            }}
            next
        }}
        {{
            for (i = 2; i <= NF; i++) {{
                filename = "results/phenotype/traits/" colnames[i] ".txt"
                print $1 "\t" $i >> filename
            }}
        }}
        ' {input.pheno} >> {log} 2>&1
        """

