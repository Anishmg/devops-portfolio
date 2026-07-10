# Airflow on EKS — MWAA Migration with a Custom Image

## Problem

The platform's ETL runs on Apache Airflow, orchestrating pipelines that pull from
60+ data sources. It originally ran on **MWAA** (AWS-managed Airflow), which was
convenient but limiting: constrained control over the runtime, harder dependency
management, and cost/scaling tradeoffs we didn't control.

The goal was to move to **self-managed Airflow on EKS** — full control over the
image, the executor, and autoscaling — without breaking the existing DAGs, which
depend on a heavy and unusual set of system and Python dependencies.

## The hard part: reproducing the runtime

The DAGs don't just need Python packages — they need a lot of **system-level**
tooling that MWAA's bootstrap had provided. Getting a container image that matched
what the DAGs expected was the real work. The custom image had to include:

- **Browser automation:** Chromium + ChromeDriver and Playwright (with all the
  shared libraries a headless browser needs) for scraping-style DAGs.
- **Document/OCR toolchain:** Poppler, Tesseract OCR, QPDF, and LibreOffice for
  PDF and document processing.
- **Archive handling:** the *real* (non-free) `unrar`, because the default
  `unrar-free` can't read RAR5 archives — a subtle bug that silently broke
  extraction until I enabled the correct Debian repo.
- **JVM:** a headless JRE for Apache Tika and PySpark.
- **ML libraries:** PyTorch (CPU build to keep the image lean), Hugging Face
  Transformers, and Amazon's Chronos time-series library, installed from source.

The Dockerfile ends with a **verification step** that imports every critical
dependency at build time, so a broken image fails the build instead of failing a
DAG at 3 a.m.

## Deployment

- Built and pushed the image to **ECR** via a GitHub Actions workflow that triggers
  only when the `Dockerfile` or `requirements.txt` changes, tagging each build with
  `latest`, the short Git SHA, and a timestamped version tag for traceable
  rollbacks.
- Deployed Airflow to EKS via **Helm** using the `KubernetesExecutor`, so each task
  runs in its own pod and DAG workloads autoscale via Karpenter.
- Kept the Helm values as the single source of truth in the Terraform repo.

## What this demonstrates

Migrating a managed service to self-managed without regressions, deep Docker
dependency work (system libraries, not just `pip install`), catching a subtle
RAR5/unrar-free bug, and build-time verification as a reliability practice.

**Tech:** Apache Airflow, Docker, Amazon ECR, EKS, Helm, KubernetesExecutor,
GitHub Actions, Karpenter
