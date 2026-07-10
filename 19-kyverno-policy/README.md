# Kyverno — Policy-as-Code Guardrails

## Problem

On a shared, multi-tenant cluster where many engineers and automated pipelines can
all run `kubectl`, a single mistaken command can delete something critical — a
Deployment, a Service, a PVC holding user data, a Secret, a ConfigMap, or even a
whole namespace. Relying on everyone being careful doesn't scale.

This isn't hypothetical on this platform: accidental deletions have caused real
incidents, including 53 user volumes being wiped and namespace/tag deletions that
triggered outages. Kyverno is the systemic answer to that entire class of problem —
enforced guardrails that make dangerous actions *impossible*, not just discouraged.

## What I built

I designed and deployed a Kyverno `ClusterPolicy` (`prod-protect-namespaced-resources`)
running in **Enforce** mode, with three rules working at the Kubernetes admission
layer:

1. **Block deletion of namespaced resources** — denies `DELETE` on Deployments,
   Services, Ingresses, PersistentVolumeClaims, Secrets, ConfigMaps, and CronJobs
   across **24 protected namespaces** (app, app-microapps, airflow, karpenter, keda,
   the pms/prodigy service namespaces, velero, the monitoring namespace, and more).
2. **Block namespace deletion** — denies `DELETE` on the protected namespaces
   themselves, so an entire namespace can't be dropped.
3. **Block PersistentVolume deletion** — denies `DELETE` on PVs cluster-wide, so the
   underlying storage behind user data can't be removed.

Because Kyverno intercepts at the **admission** layer, the protection applies no
matter how the delete is attempted — kubectl, a pipeline, or a script. The API
server itself refuses the operation and returns a clear message
(e.g. "🚫 Deletion of namespace-scoped resources is blocked").

## The exclusions — the part that makes it usable

A blanket "block all deletes" would break the cluster's own automation, so the
policy carves out precise exceptions:

- **`system:masters`** — cluster admins can still act deliberately when genuinely
  needed.
- **`ebs-csi-controller-sa`** and **`system:nodes`** — so the storage driver and
  nodes can manage volumes normally.
- **`namespace-controller`** — so Kubernetes' own lifecycle controllers work.
- **`github-actions`** — so the CI/CD deployment pipelines can still roll out
  changes.
- **Helm release secrets (`sh.helm.release.*`)** — so Helm upgrades aren't blocked.
- **`pod-status-checker`** — a platform service that manages its own resources.

Getting these exclusions right is the actual engineering: the guardrail has to stop
*accidents* without breaking *legitimate automation*.

## Managed via GitOps

The policy is delivered through **ArgoCD** (see
[20-argocd-gitops](../20-argocd-gitops)), so the guardrails themselves are
version-controlled and continuously reconciled — the protection can't silently drift
or be edited away, because ArgoCD syncs it back to the committed state.

## What this demonstrates

Policy-as-code security engineering, using admission control to enforce guardrails at
the API layer, protecting a shared multi-tenant cluster from a real and recurring
class of incident, and the judgment to scope exclusions so automation keeps working.

**Tech:** Kyverno (ClusterPolicy, admission control, Enforce mode), Kubernetes,
policy-as-code, ArgoCD, EKS
