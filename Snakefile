# =============================================================
# Snakefile
# GWAS Workflow with Singularity Container
# =============================================================

configfile: "config.yaml"

import os
import pandas as pd

# -------------------------------------------------------------
# 全局设置
# -------------------------------------------------------------
os.environ["TMPDIR"] = config["tmpdir"]

OUTDIR = config["project"]["outdir"]

# 全局容器声明
singularity: config["container"]


# -------------------------------------------------------------
# 提前读取 trait 名称（从表型文件 header）
# -------------------------------------------------------------
TRAITS = pd.read_csv(
    config["phenotype"]["input"],
    sep="\t",
    nrows=0
).columns.tolist()[1:]   # 去掉第一列（样本名）

# -------------------------------------------------------------
# GWAS 模型列表
# -------------------------------------------------------------
MODELS = config["gwas"]["models"]


# -------------------------------------------------------------
# Admixture 可开关输出
# -------------------------------------------------------------
ADMIXTURE_OUTPUT = (
    [
        f"results/admixture/CV.error.txt",
        f"results/admixture/tassel.Q.txt"
    ]
    if config["admixture"]["enabled"]
    else []
)

# -------------------------------------------------------------
# 引入规则文件
# -------------------------------------------------------------
include: "rules/qc.smk"
include: "rules/beagle.smk"
include: "rules/reheader.smk"
include: "rules/pca.smk"
include: "rules/kinship.smk"
include: "rules/admixture.smk"
include: "rules/phenotype.smk"
include: "rules/gwas.smk"
include: "rules/plot_gwas.smk"

# -------------------------------------------------------------
# 最终目标
# -------------------------------------------------------------
rule all:
    input:
        # --- QC ---
        "results/qc/data.qc2.vcf.gz",
        "results/qc/data.qc2.vcf.gz.tbi",

        # --- PCA ---
        "results/pca/covariates.txt",
        "results/pca/scree_summary.txt",

        # --- Kinship ---
        f"results/kinship/{config['kinship']['out_prefix']}.txt",

        # --- Admixture（可开关）---
        *ADMIXTURE_OUTPUT,

        # --- 表型 ---
        "results/phenotype/trait_list.txt",
        expand(
            "results/phenotype/traits/{trait}.txt",
            trait=TRAITS
        ),

        # --- GWAS（模型 × trait 全组合）---
        expand(
            "results/gwas/{model}/{trait}/{trait}_{model}_results.txt",
            model=MODELS, trait=TRAITS
        ),

        # --- GWAS 结果绘制 ---
        expand(
            "results/gwas/{model}/{trait}/plots/Rect_Manhtn.1.pdf",
            model=MODELS, trait=TRAITS
        )
