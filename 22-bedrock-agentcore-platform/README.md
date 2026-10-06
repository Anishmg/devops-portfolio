# Amazon Bedrock AgentCore Platform — Multi-Environment Build

## Problem

The platform's multi-agent AI system needed a production-grade home. Amazon Bedrock
AgentCore Runtime is a managed service — you give it a container image and AWS runs
it — but everything around the runtime is yours to build: networking, identity,
configuration, scheduling, data stores, routing and deployment.

The first environment was assembled by hand and released from a laptop. The goal was
repeatable environments — demo, staging, and a client tenant in a **separate AWS
account and region** — each genuinely isolated from the others, with every release
going through CI/CD.

## What I built

- **The runtime** — an arm64 (Graviton) container, VPC-attached behind an
  outbound-only security group (traffic only ever flows out; nothing connects in).
  In the client tenant it spans three availability zones.
- **A backend "bridge"** on Kubernetes that receives authenticated web requests (the
  JWT is checked at an API gateway) and calls the runtime.
- **Code Interpreter** — an AWS-managed sandbox so the assistant can run code in an
  isolated session per conversation. It needed one configuration flag and four
  narrowly scoped IAM actions, and no infrastructure.
- **Scheduled automations** — the runtime registers a schedule in EventBridge
  Scheduler, the scheduler invokes a VPC-attached Lambda, and the Lambda calls the
  runtime back to do the work.
- **Data** — chat history, sessions and automations on shared PostgreSQL (moved off
  per-user SQLite volumes), files in S3 under environment-specific prefixes.
- **Four purpose-scoped IAM roles** — runtime, pod (via IRSA), scheduler and Lambda —
  each with a conditioned trust policy and resources scoped to named prefixes.

## Key design decisions

- **Configuration lives in Secrets Manager, not the image.** The runtime used to
  bake its whole `.env` into the container, so anyone able to pull the image could
  read every key, and a one-character change meant a 20-minute rebuild. The runtime
  now reads its secret at boot.
- **One image per environment, pointing at its own secret.** AgentCore's API accepts
  only an image — there are no environment variables. So the *name* of the secret is
  baked in as a build argument: same code, same Dockerfile, a different pointer.
- **The image must be in the runtime's own region.** For the client tenant in another
  region, I replicated images with `crane` (registry to registry, no Docker daemon)
  and changed CI so future builds push to the right region automatically.
- **The first runtime is always created by hand** — CI/CD can only update a runtime
  that already exists. Every new environment has exactly one manual step.
- **Isolate data and configuration; share plumbing.** Each environment has its own
  runtime, secret, database, namespace and domain. Only things that cannot leak data
  (the registry, the database host with separate databases, the IAM roles) are shared.

## Problems that were hard to see

- **Automations silently fell back to an in-process timer** that dies on restart.
  The cause was four separate IAM gaps — a missing sub-resource ARN, a list action
  that needs a wider resource pattern than the other scheduler actions, an inline
  policy that hit its 2,048-byte limit, and an unreadable secret — plus session IDs
  that must be at least 33 characters.
- **Static AWS keys copied into the secret overrode IRSA**, because the SDK reads
  environment variables before the pod's role.
- **Multi-line JSON in a `.env` secret** made the runtime start "healthy" with zero
  tools, because the parser stops at the first newline.

## Delivery pipeline

A manual `docker build` from a laptop became three workflows: runtime, backend and
Lambda. The runtime build emulates arm64 with QEMU, runs a Trivy scan that **fails
on critical vulnerabilities before anything is deployed**, pushes a timestamped tag,
updates the runtime and waits for READY. Each workflow supports deploy, build-only,
rollback and restart. The check that matters after a deploy is the **tool count** —
a runtime can report READY with no tools at all.

## What this demonstrates

Building a managed AI runtime into a real platform: least-privilege IAM design,
multi-environment and cross-account isolation, secrets handling under a constrained
API, CI/CD with a security gate, and diagnosing failures that look like success.

**Tech:** Amazon Bedrock AgentCore, EventBridge Scheduler, Lambda, IAM / IRSA,
Secrets Manager, PostgreSQL (RDS), ECR, EKS, Kong, GitHub Actions (OIDC), Trivy
