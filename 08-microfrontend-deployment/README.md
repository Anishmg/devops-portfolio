# Micro-Frontend Deployment on EKS

## Problem

The platform's UI is a **micro-frontend (MFE) architecture**: ~30+ independently
built Next.js apps (one per feature area — maintenance, procurement, crew, voyage, etc.) plus a
shell app that stitches them together. All of them deploy to EKS across the same
multiple client environments as the backend.

Two things make MFE deployment genuinely hard, and both had to be solved:

### Challenge 1 — env needed at *both* build time and runtime

Next.js bakes `NEXT_PUBLIC_*` variables into the static bundle **at build time**,
but other configuration is only known **at runtime** (and differs per client). So a
single image can't just be built once and run anywhere — the build needs the right
public env for that environment, and the running container needs its runtime env
too. Getting this wrong means an app that's built for one client silently calls
another client's APIs.

I handled this with a **multi-stage Docker build**: a `deps` stage installs
dependencies (including a shared design-system package), a `builder` stage builds
with the correct build-time env and then **deletes the `.env` file** so no secrets
or stale config leak into the image, and a lean `runner` stage ships only the
Next.js standalone output. Runtime configuration is then injected into the pod
separately, per client.

### Challenge 2 — 30+ apps, don't rebuild everything every time

Rebuilding and redeploying all 30+ MFEs on every change would be painfully slow. The
pipeline needed to build only what actually changed.

## Approach — Helm chart + change-aware pipeline

- **One Helm chart (`mfe-eks`) for all MFEs**, with a `values-<client>.yaml` per
  environment (prod, QA, and per-client environments). The chart templates
  the deployments, services, ingress, and namespace for every MFE from those values,
  so hostnames like `maintenance.apps.<client-domain>` are generated consistently.
- **Change detection in CI.** The GitHub Actions workflow diffs the commit and
  builds only the MFEs whose directories changed (with a manual override to force a
  specific list or deploy-all). Helm-chart changes are detected separately so a
  chart update can re-render all services when needed.
- **Multi-environment dispatch.** A `workflow_dispatch` input selects the target
  client, so the same pipeline deploys to any environment on demand.
- Images are built and pushed to **ECR**, then rolled out to EKS.

## What this demonstrates

Solving the build-time-vs-runtime env problem cleanly (the core difficulty of MFE
deployment), multi-stage Docker builds that don't leak config, Helm templating
across 30+ services and multiple clients, and a change-aware pipeline that keeps
deploys fast.

> The MFE application code is owned by the development teams; the Helm chart,
> Docker build strategy, env handling, and deployment pipeline documented here are
> my work.

**Tech:** Kubernetes, Helm, Docker (multi-stage), Next.js build model, GitHub
Actions, Amazon ECR, EKS
