# Multi-Client Core-Services Deployment

## Problem

The platform's backend is a set of core services — auth, core service, API gateway,
reporting, tracking, a workflow service, a web frontend, and an edge gateway. These have
to be deployed for **multiple clients** (production, plus separate isolated client,
QA, and dev environments), each with its own namespace, hostnames, resource
sizing, database endpoints, and configuration.

Copy-pasting a full set of manifests per client would be unmaintainable and would
guarantee drift. The deployment layer needed to be **DRY, consistent, and safe to
roll out one client at a time**.

## Approach — Kustomize base + per-client overlays

I structured the whole thing as a Kustomize **base** (the shared shape of each
service) with a thin **overlay per client** that patches only what differs:

```
k8s/
  base/
    auth/  core-service/  api-gateway/  reporting/  tracking/
    workflow-service/  web-frontend/  edge-gateway/  ...
  overlays/
    prod/       (production)
    client-a/   (client)
    client-b/   (client)
    qa/
    dev/
      <service>/
        namespace.yaml
        deployment-patch.yaml   # image, resources, replicas
        service-patch.yaml
        ingress.yaml            # per-client hostnames
        sa-patch.yaml           # IRSA service account
        kustomization.yaml
```

Each overlay overrides only the deltas: the container image tag, resource
requests/limits, replica counts, HPA settings, the ingress hostnames, and the IAM
service account. Everything common stays in the base and is defined exactly once.

## CI/CD

Deployment runs through GitHub Actions with a **reusable workflow template**
(`_deploy-template.yml`) that each service's workflow calls. That means all ~9
services deploy through the same audited, parameterized path rather than nine
divergent scripts. Auth to AWS/EKS is via OIDC (no static keys), and rollouts can
be done **per client**, so a change can be validated on QA or one client
before it reaches production.

## Handling secrets correctly

Per-client configuration and connection details are injected via Kubernetes
Secrets / config, sourced from a secret store — kept **out** of the base manifests
so the shared layer carries no client-specific credentials.

> *Note: while working in this area I also found and flagged legacy plaintext
> secrets that predated the secret-store approach, and recommended rotating them
> and moving them into managed secrets — part of the ongoing security hardening.*

## What this demonstrates

Multi-tenant Kubernetes deployment design, Kustomize base/overlay modeling, DRY
CI/CD via reusable workflow templates, safe progressive rollout across clients, and
IRSA-based per-service permissions.

**Tech:** Kubernetes, Kustomize, Helm, Kong, GitHub Actions (OIDC), EKS, IRSA, HPA
