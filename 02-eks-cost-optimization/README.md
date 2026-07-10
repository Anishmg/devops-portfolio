# EKS Cost Optimization (FinOps)

Two related pieces of work that meaningfully cut the platform's AWS bill: right-
sizing the EKS compute fleet with Karpenter, and eliminating wasteful CloudWatch
ingestion.

---

## Part 1 — Karpenter node consolidation

### Problem

The EKS cluster had grown to **125 nodes**. A chunk of that was waste: an
autoscaling misconfiguration meant nodes weren't consolidating, some node pools
were picking oversized instance types that fit only one workload each, and a set
of "zombie" nodes were stuck and never reclaimed.

### Investigation

- Found the Karpenter disruption budget was set to `5%`, which rounded down to `0`
  on smaller fleets — silently **blocking all consolidation**.
- Found a node pool with no instance-size restriction, so Karpenter kept launching
  large instances that fit only a single user VM each (terrible bin-packing).
- Identified zombie nodes held by a stuck pod lease and by a
  `do-not-disrupt` annotation left on a resource, both preventing reclamation.
- Traced subnet IP exhaustion to Kubernetes discovery tags that had been deleted
  from a subnet, so Karpenter had stopped using ~500 available IPs.

### Fix

- Corrected the disruption budget to a fixed `1` node so consolidation could run.
- Restricted the node pool to a right-sized instance type, improving VMs-per-node
  ~3x.
- Cleared the stuck lease and removed the stale `do-not-disrupt` annotation;
  Karpenter resumed consolidation within seconds.
- Re-added the missing subnet tags, restoring ~500 IPs to the scheduler.

### Result

**125 → 82 nodes** (‑43), with zero zombie/empty/drifted nodes remaining.
Estimated compute saving on the order of **~$790/day**.

---

## Part 2 — CloudWatch cost reduction

### Problem

The CloudWatch bill for one cluster was **~$4,212/month** and nobody could explain
it.

### Investigation

I broke the bill down by source and found the cost was almost entirely waste:

- A **failed ContainerInsights addon** (stuck in a create-failed state) was still
  billing ~$65/day for duplicate metric series that Prometheus already collected.
- An internal **performance log group** with zero consumers, ingesting hundreds of
  GB/week.
- **Log spam** from an ingress controller stuck in an error loop over hundreds of
  stale routes, producing the majority of application-log cost.
- Orphaned **S3 Firehose export streams** still billing after their destinations
  were deleted.

### Fix

Removed the failed addon, deleted the orphaned Firehose streams, got the ingress
controller's log level turned down and its stale routes cleaned up, and confirmed
no real telemetry was lost in the process (Prometheus already covered the metrics).

### Result

**~$4,212/month → ~$454/month** — an **89% reduction**, roughly **$43,000/year**.

---

## What this demonstrates

Cost-driver analysis from billing and usage data, Karpenter internals
(disruption budgets, consolidation, bin-packing), and the discipline to verify no
observability was lost while cutting spend.

**Tech:** AWS EKS, Karpenter, CloudWatch, Prometheus, Cost analysis
