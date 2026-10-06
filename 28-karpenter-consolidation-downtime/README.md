# Karpenter Consolidation Downtime — Making Cost Savings Safe

## Problem

Karpenter saves money by **consolidating** — evicting pods from under-used nodes so
the nodes can be removed. That is exactly what cut the cluster from 125 nodes to 82.
But it is also a voluntary disruption, and any service that cannot tolerate losing a
pod will blink every time it happens. Two services did.

## Case 1 — a front-end shell service (~2 minutes of downtime)

**What happened.** The service ran a **single replica**. Karpenter evicted it from an
under-utilised node, and the replacement landed on a brand-new node that had no
network interfaces ready yet. Pod-sandbox creation failed eight times (about two and
a half minutes) before the pod started.

**Root causes.** One replica, and no PodDisruptionBudget — so nothing stopped
Karpenter evicting the only pod.

**Fixes.**

- **A PodDisruptionBudget** (`minAvailable: 1`), so Karpenter can no longer evict the
  last pod.
- **Two replicas**, through a per-service value in the Helm template, so only this
  service changes and every other service keeps its default.
- **A per-service HPA minimum.** After scaling to two by hand, the HPA kept putting it
  back to one — its global `minReplicas` was 1 and CPU and memory were far below the
  target, so it saw nothing to protect. The chart now takes `minReplicas` per service.
- **A temporary live patch** to the HPA until the pull request merged. A change made
  with `kubectl` is wiped by the next deploy, so the repository change is the real fix.

A PDB on its own is not enough: with `minAvailable: 1` and one replica, a drain can
never proceed. Protection needs **both** the budget and a second replica.

## Case 2 — the backend bridge service (intermittent API failures)

**What happened.** Pods were being scheduled onto nodes from the autoscaled pool, whose
nodes expire after seven days. Constant consolidation and expiry kept evicting them,
and there was no PDB, so **both replicas could be disrupted at once**. One pod was found
on a node only twelve minutes old.

**Fixes.**

- A **PDB** straight away, so at most one pod can be evicted at a time and the other
  keeps serving.
- A **node selector, via pull request**, that pins the service to a fixed-size managed
  node group — no autoscaling, no consolidation. That group had plenty of headroom
  (single-digit to low-teens CPU use).

**The trade-off.** Pinning gives stability but gives up consolidation savings for that
workload. It's the right call for a latency-sensitive service on a group that is
already lightly used.

## What this demonstrates

Understanding the second-order effect of a cost optimisation, using disruption budgets
correctly (and knowing their limit), per-service configuration instead of global
changes, and making a live fix permanent in the repository.

**Tech:** Karpenter, Kubernetes (PodDisruptionBudget, HPA, node selectors), Helm,
Kustomize, EKS managed node groups
