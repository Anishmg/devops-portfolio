# MCP Wrapper Deployment

## Problem

The platform runs an **MCP (Model Context Protocol) wrapper** — a service that
aggregates many upstream MCP servers behind a single endpoint for the AI system to
consume. It has to run as separate instances per client environment
(production, dev, QA, and per-client), each needing a large set of credentials
and upstream configuration to come up correctly.

> The MCP wrapper application is built by the Data Science / development team. My
> work is the **deployment and configuration** — getting it running reliably across
> environments with its secrets managed properly.

## Approach — secrets-driven, multi-instance deployment

Each MCP wrapper instance needs a large bundle of credentials (upstream service
keys, database URIs, tokens). I managed these through **AWS Secrets Manager**, one
secret per environment, synced into the corresponding Kubernetes secret that the
deployment consumes — so:

- No credentials live in the repo or in manifests.
- Each environment (prod, dev, qa, client-a, client-b) has its own isolated secret.
- Rotating or adding a key is a Secrets Manager update plus a rollout, not a code
  change.

## Operational reliability

Most of my work here was keeping the instances healthy, which mostly meant tracing
startup failures back to configuration:

- **Missing-key crashes.** The wrapper fails hard at startup if a required env var
  (e.g. an upstream username) isn't set. I diagnosed these config-load crashes and
  fixed them by syncing the missing keys from Secrets Manager — and documented the
  rule that keys must not be deleted from a secret while the config still references
  them.
- **Broken image rollbacks.** When a new image shipped with missing upstream
  binaries (every upstream failing with a "not found" error), I identified the bad
  build and rolled the deployment back to the last working image to restore service
  immediately.
- **Health verification.** Checked all upstreams-ready status per instance and the
  external endpoints, so a partially-degraded wrapper (some upstreams down) gets
  caught rather than silently serving a subset of tools.

## What this demonstrates

Secrets-managed multi-environment deployment, methodical startup-failure debugging
(config load, missing keys, bad images), and fast incident recovery via rollback.

**Tech:** Kubernetes, AWS Secrets Manager, EKS, deployment/rollout management
