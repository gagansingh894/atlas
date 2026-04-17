# Command: ML Overview

Orchestrates exploration of the machine learning components in the current repository and produces (or refreshes) `.atlas/ml-overview.md`.

Works in:
- **Pure ML repos** (research, training pipelines, notebooks)
- **Hybrid repos** (ML models embedded in a larger service — complement with `codebase-overview`)

---

## Step 0 — Handle `--help`

If the user passes `--help` or `-h`, print the following and do nothing else:

```
ml-overview — Generate or refresh a comprehensive ML codebase overview

USAGE
  ml-overview [options]

DESCRIPTION
  Scans the current repo for ML artefacts and writes .atlas/ml-overview.md
  covering: model inventory, data sources, feature engineering, training
  pipelines, experiment tracking, evaluation, serving/inference, retraining
  triggers, monitoring, and environment/reproducibility.

  If .atlas/codebase-index.json exists, it is used to fast-path ML artifact
  detection before any file exploration.

  If the file already exists, merges new findings rather than overwriting.

OPTIONS
  --output <path>    Override output path (default: .atlas/ml-overview.md)
  --focus <area>     Give extra depth to one area, e.g. --focus "training pipeline"
  --fresh            Skip merge — write a completely new file from scratch
  --help, -h         Show this help and exit

OUTPUT FILES
  .atlas/ml-overview.md

RELATED SKILLS
  codebase-overview      — General service architecture (complement for hybrid repos)
  architecture-diagram   — Visual diagram of the ML pipeline
  ecosystem-overview     — Cross-repo view if ML is one service among many
```

---

## Step 1 — Detect existing ML overview and index

Check for:
- `.atlas/ml-overview.md` (or `--output` path) — existing overview to merge into
- `.atlas/codebase-index.json` — structured index that may fast-path ML artifact detection

**If index exists:** read it. Use `architecture.frameworks` and `files[].component_type` to immediately identify files likely containing ML code. This avoids a full directory scan for ML artifacts.

**If overview exists and `--fresh` not passed:** read it in full, record the `Last updated` date. You will merge rather than replace.

---

## Step 2 — Read existing docs

Read the following if present:
- `CLAUDE.md` / `README.md`
- `.atlas/codebase-overview.md` (to avoid duplication with general architecture)
- Any other files in `.atlas/`

---

## Step 3 — Detect ML artefacts

**Fast path:** if `.atlas/codebase-index.json` exists, check `architecture.frameworks` for ML libraries and `files[]` for ML-related symbols.

**Full scan** (if no index): scan the repo for signals of ML code:

**Model files & frameworks:**
- `*.pt`, `*.pth`, `*.ckpt`, `*.pb`, `*.h5`, `*.onnx`, `*.pkl`, `*.joblib`, `*.safetensors`
- Imports: `torch`, `tensorflow`, `keras`, `sklearn`, `xgboost`, `lightgbm`, `catboost`, `jax`, `flax`, `transformers`, `diffusers`, `spacy`, `nltk`

**Training infrastructure:**
- `train.py`, `fit.py`, `run_training.py`, files with `trainer` in name
- `Makefile` targets: `train`, `finetune`, `evaluate`
- SageMaker: `estimator`, `TrainingJob`, `HyperparameterTuner`
- Vertex AI: `CustomTrainingJob`, `AutoML`

**Data pipelines:**
- `data/`, `datasets/`, `raw/`, `processed/`, `features/`
- DVC: `*.dvc`, `dvc.yaml`, `dvc.lock`
- Airflow: `dags/`, `DAG(`, `PythonOperator`
- Prefect / Luigi / Metaflow / Kedro config files

**Experiment tracking:**
- `mlflow`, `wandb`, `comet_ml`, `neptune`, `clearml`, `tensorboard`

**Feature engineering:**
- `feast`, `tecton`, `hopsworks` imports
- `feature_store`, `features.py`, `feature_pipeline`

**Serving / inference:**
- `serve.py`, `inference.py`, `predictor.py`, `handler.py`
- `torchserve`, `triton`, `bentoml`, `ray serve`, `seldon`, `kfserving`
- FastAPI/Flask endpoints that load a model

**Notebooks:** `*.ipynb` — read titles and first few cells

---

## Step 4 — Deep exploration

Using the artefacts found, read the key files. Cover:

1. **Model inventory** — every distinct model, framework, architecture, task type
2. **Training pipelines** — entry points, config/hyperparameter management, hardware requirements
3. **Data sources** — origin, format, volume if documented
4. **Data versioning** — DVC, LFS, manifest files, or none
5. **Feature engineering** — preprocessing steps, feature stores, online vs offline
6. **Experiment tracking** — tool used, what is logged (metrics, artefacts, params, model versions)
7. **Evaluation strategy** — metrics, validation approach, benchmark datasets
8. **Model registry & versioning** — how trained models are stored and promoted
9. **Serving / inference** — deployment target, serving framework, batch vs real-time
10. **Monitoring & drift detection** — tools, what is monitored, alerting
11. **Retraining triggers** — scheduled, performance-triggered, data-volume-triggered, or manual
12. **Environment & dependencies** — Python version, key packages, CUDA requirements, Docker images

---

## Step 5 — Generate content

Produce all required sections (see below). Always include concrete file paths: `src/train.py:Trainer.fit()`. For notebooks, reference `notebooks/01_exploration.ipynb`.

---

## Step 6 — Merge with existing file (if one exists)

**Do NOT blindly overwrite.** Apply per-section merge rules:
- **Structurally changed** (new models, renamed pipelines, removed flows) → replace with new content
- **Additive only** (new experiments, new data sources, new nuances) → merge in; keep existing accurate items
- **Unchanged** → keep existing wording
- **Uncertain** → keep content and append `<!-- verify -->`

---

## Step 7 — Write the final file

Output file must begin with:

```
<!-- Last updated: YYYY-MM-DD -->
```

Then a cross-reference block linking to companion docs, followed by the full content.

---

## Required Sections

### 1. ML Components at a Glance
Table: model/pipeline, task type, framework, status, entry point.

### 2. Model Inventory — Deep Dive
Per model: architecture, input/output schema, key hyperparameters, pretrained base, where the artefact lives.

### 3. Data Sources & Ingestion
Origin, formats, schemas, data versioning strategy, data quality/validation steps.

### 4. Feature Engineering Pipeline
Preprocessing steps, feature store usage, train/inference feature parity (critical — common source of silent bugs).

### 5. Training Pipelines
How to trigger a run, config/hyperparameter management, distributed training setup, hardware requirements.

### 6. Experiment Tracking & Model Registry
Tool used, what is logged, how to find past experiments, model promotion workflow.

### 7. Evaluation & Metrics
Primary and secondary metrics, validation strategy, benchmark datasets, where evaluation scripts live.

### 8. Serving & Inference
Deployment target, batch vs real-time, input/output contract, model loading pattern, latency SLAs.

### 9. Retraining & Continuous Learning
What triggers retraining, end-to-end retraining flow with file paths, validation before promotion.

### 10. Monitoring & Drift Detection
What is monitored, tool used, alerting thresholds.

### 11. E2E ML Flows with Code Paths
- **Training flow**: raw data → features → train → evaluate → register
- **Inference flow**: request → feature lookup → model.predict() → response
- **Retraining flow**: trigger → data pull → train → evaluate → promote

### 12. Tricky Parts & ML-Specific Nuances
Non-obvious issues (8–15 items). Look for: train/serving skew, data leakage, class imbalance, non-determinism, cold-start, version pinning issues, implicit timestamp assumptions.

### 13. Environment & Reproducibility
Python version, key package versions, how to reproduce the environment, CUDA requirements, known reproducibility issues.

### 14. Key File Quick Reference
Table of most important files with single-line purpose.

---

## Parameters

- `--output <path>`: Override output path (default: `.atlas/ml-overview.md`)
- `--focus <area>`: Extra depth on a specific area
- `--fresh`: Skip merge — write completely new file

---

## Notes

- **Train/serving skew is the single most common source of silent ML bugs.** Always investigate whether features are computed identically at training and serving time.
- **The index fast-path saves time.** If `.atlas/codebase-index.json` exists, use it to identify ML files before scanning.
- For notebooks (`*.ipynb`): read markdown cells and cell outputs, not just code.
- If no experiment tracking is found, note this explicitly — it is a significant operational risk.
- If `.atlas/` does not exist, create it.
- The `<!-- Last updated: YYYY-MM-DD -->` line must always be the first line of the output file.
