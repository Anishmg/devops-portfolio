# Per-User Container Provisioning Service

## Problem

The platform gives each user their own isolated workspace container ("cloud
computer") — a dedicated pod per user, created on demand and cleaned up when no
longer needed. That requires something to programmatically create, track, and tear
down Kubernetes workloads per user, with a clean API the rest of the platform can
call.

## Approach — a FastAPI control service on Kubernetes

I built (and operate) a **FastAPI** service that acts as the control plane for these
per-user containers, talking to the Kubernetes API directly:

- `POST /containers/` — create a container for a user (or return the existing one if
  it's already running), with configurable image and CPU/memory limits.
- `DELETE /containers/{user_id}` — tear a user's container down.
- `GET /health` — health/status for monitoring.

Under the hood it uses the Kubernetes Python client to create and manage the
Deployment/Service per user, deriving a stable per-user service URL, and handling
the lifecycle (create → running → delete).

## Operational engineering

The service itself runs in-cluster, so it:

- **Auto-detects its context** — loads in-cluster config when running as a pod, and
  falls back to local kubeconfig for development.
- Logs to both stdout and a file so container logs are visible in the platform's log
  stack.
- Runs from a container image built for the cluster.

Much of my work here was operational reliability: debugging pods stuck in `Pending`
or `Terminating`, right-sizing per-user resource limits, and handling the node
scheduling/rescheduling behavior when Karpenter consolidates nodes underneath a
large population of user pods (400+ active user VMs at peak).

## What this demonstrates

Programmatic Kubernetes control (not just kubectl — driving the API from code),
designing a lifecycle API, in-cluster vs local config handling, and operating a
large, dynamic pod population under autoscaling.

> The service is infrastructure I own; it provisions containers for the wider
> platform. Application code that runs *inside* the user containers is separate.

**Tech:** Python, FastAPI, Kubernetes (Python client), Docker, EKS, Karpenter
