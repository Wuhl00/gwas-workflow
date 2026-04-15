# GWAS Snakemake Workflow (TASSEL-based)

A reproducible, container-based GWAS pipeline built with Snakemake and TASSEL. It handles genotype QC, phasing, PCA/Admixture covariate generation, multi-model GWAS, and automatic Manhattan / QQ plot production — all driven by a single `config.yaml`.

---

## Features

- End-to-end workflow from raw VCF to publication-ready plots
- Supports **GLM**, **MLM**, and **CMLM** models via TASSEL
- Uses the **top 5 PCA components** as covariates by default
- Optional **ADMIXTURE Q-matrix** as an alternative covariate source *(experimental, untested)*
- Phenotype file is **automatically split** by trait; results are organised per model × trait
- Fully containerised via **Singularity** for reproducibility

---

## Directory Structure

```
gwas_snakemake/
├── Snakefile
├── config.yaml
├── rules/
│   ├── qc.smk
│   ├── beagle.smk
│   ├── reheader.smk
│   ├── pca.smk
│   ├── kinship.smk
│   ├── admixture.smk
│   ├── phenotype.smk
│   ├── gwas.smk
│   └── plot_gwas.smk
└── results/               # auto-generated
```

---

## Requirements

| Software | Notes |
|----------|-------|
| Snakemake ≥ 7.x | Workflow engine |
| Singularity | All tools run inside the declared container |
| Python ≥ 3.8 | With `pandas` installed in the Snakemake env |

All bioinformatics tools (TASSEL, BEAGLE, PLINK, R/CMplot, etc.) are expected to be available inside the Singularity container specified in `config.yaml`.

---

## Input Files

| Item | Description |
|------|-------------|
| Genotype | VCF format (`.vcf.gz`) |
| Phenotype | Tab-separated file; first column = sample ID, remaining columns = traits |

The pipeline auto-detects trait names from the phenotype file header — no manual listing required.

---

## Configuration

All parameters are set in `config.yaml`. Key fields:

```yaml
container: "path/to/.sif or pull"       # Singularity image
tmpdir: "/tmp"

project:
  outdir: "results"

phenotype:
  input: "data/phenotype.txt"        # Tab-separated; 1st col = sample ID

kinship:
  out_prefix: "kinship"

gwas:
  models:                            # Any combination of GLM / MLM / CMLM
    - GLM
    - MLM
    - CMLM

admixture:
  enabled: false                     # Set true to use Q-matrix as covariate
                                     # ⚠ Experimental — not fully tested
```

---

## Running the Pipeline

```bash
# Dry run (check DAG without executing)
snakemake -n --use-singularity

# Full run with Singularity (adjust -j to available cores)
snakemake --use-singularity \
          --singularity-args "-B $(pwd):/workspace" \
          -j 8 --printshellcmds
```

---

## Workflow Overview

```
Raw VCF
   │
   ▼
[QC] ──────────────────────────────── data.qc2.vcf.gz
   │
   ▼
[Phasing — BEAGLE]
   │
   ▼
[Reheader]
   │
   ├──► [PCA] ──► covariates.txt (PC1–PC5)   ← default covariate
   ├──► [Kinship matrix]
   ├──► [Admixture Q-matrix] *(optional / experimental)*
   └──► [Phenotype split] ──► results/phenotype/traits/{trait}.txt
   │
   ▼
[GWAS — TASSEL]  (GLM / MLM / CMLM  ×  all traits)
   │
   ▼
[Plot] ──► Manhattan plot + QQ plot per model × trait
```

---

## Output Structure

```
results/
├── qc/
│   ├── data.qc2.vcf.gz
│   └── data.qc2.vcf.gz.tbi
├── pca/
│   ├── covariates.txt
│   └── scree_summary.txt
├── kinship/
│   └── <out_prefix>.txt
├── admixture/                  # only if enabled: true
│   ├── CV.error.txt
│   └── tassel.Q.txt
├── phenotype/
│   ├── trait_list.txt
│   └── traits/{trait}.txt
└── gwas/
    └── {model}/
        └── {trait}/
            ├── {trait}_{model}_results.txt
            └── plots/
                ├── Rect_Manhtn.1.pdf
                └── {trait}_{model}_QQ.png
```

---

## Covariate Strategy

By default the pipeline uses the **first 5 principal components** from PCA as covariates, which is the standard approach for controlling population structure in GWAS.

As an alternative, ADMIXTURE can be run to produce a **Q-matrix** (ancestry proportions), which can substitute for PCA covariates. To enable this, set `admixture.enabled: true` in `config.yaml`. **Note:​** this branch has not been fully tested and may require manual validation of the output before use in GWAS.

---

## Notes

- All intermediate and final outputs are written under `results/`, which is created automatically.
- The `TMPDIR` environment variable is set globally from `config["tmpdir"]` to prevent large temporary files from filling system `/tmp`.
- When running inside Singularity, ensure the working directory is correctly bind-mounted (e.g., `-B $(pwd):/workspace`) so all relative paths resolve properly inside the container.

---

### Container

This workflow uses the following Singularity container:

[library://ug2284/gwas/gwas_with_tassel:1.0](https://cloud.sylabs.io/library/hollandwu84/gwas/gwas_with_tassel)

The SHA256 checksum is provided in `gwas_with_tassel.sif.sha256`.

## License

MIT
