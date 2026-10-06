# Organisation-Wide Supply-Chain Security — 276 Repositories

## Problem

The organisation had no consistent security scanning. Some repositories had none,
and secrets, vulnerable dependencies and misconfigured infrastructure code could be
merged unnoticed. Adding scanning one repository at a time would have meant 276
different setups to maintain.

## Approach — central workflows, thin callers

I built the scanners once, as **reusable workflows in a central CI repository**, and
gave every repository a thin caller workflow pinned to a version tag (`@v1`). A rule
change, a new scanner or a fix reaches every repository without touching 276 repos
again.

What runs on every pull request to the main and develop branches:

- **Trivy** — dependency vulnerabilities, secrets, Dockerfile / Kubernetes / IaC
  misconfiguration, licences, and SBOM generation
- **Semgrep** — source-code static analysis
- **Gitleaks** — secrets in the commits the PR introduces
- **Checkov** — Kubernetes policy checks

Pull requests with critical findings are **blocked**. Alerting is deliberately
failure-only, so nobody learns to ignore it.

## Rolling it out

- Distributed callers to all **276 active repositories**, handling **dozens of
  repositories under branch protection** and a handful with non-standard default
  branches individually, then verified there were no coverage gaps.
- Ran a **baseline scan** across every active repository — six report types each,
  about 3,600 files — consolidated into one package and delivered to the application
  teams with remediation guidance.

## Decisions worth recording

- **Scan only the PR's own commits, not full history, on every PR.** Full-history
  scans run on demand and monthly; the PR path stays fast.
- **Historical secrets cannot be rewritten away.** One large repository showed 95
  historical findings across about 4,400 commits. Rewriting that history would have
  broken every clone and open branch, so I confirmed the current code was clean and
  recorded the findings by fingerprint instead. (A TOML allowlist does not apply when
  the default ruleset is extended — fingerprints do.)
- **No blanket secret inheritance.** An early version passed every secret to the
  reusable workflow; a security review flagged it, and it now passes only the explicit
  mail credentials the alerting needs.
- **Fix the false alarms.** Alert emails fired when a scan had been *skipped*, and
  reverted pull requests scanned deleted files. Both were fixed so the alerts mean
  something.
- **Exceptions are recorded, not silent.** A noisy Kubernetes rule was added to the
  skip list with the reasoning and the residual risk written down.

## What this demonstrates

Designing security automation for scale instead of repository by repository, making
trade-offs between coverage and noise, handling the awkward cases (branch
protection, history, false positives) and keeping a record of every exception.

**Tech:** GitHub Actions (reusable workflows, OIDC), Trivy, Semgrep, Gitleaks,
Checkov, CycloneDX SBOM
