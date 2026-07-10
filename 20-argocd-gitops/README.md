# ArgoCD — GitOps Continuous Delivery

## Problem

Applying changes to a cluster by hand (`kubectl apply`, manual Helm upgrades) is how
configuration drift happens: the live cluster slowly diverges from what's in Git, and
nobody can say for certain what's actually deployed or why. On a multi-tenant
production platform that's a real operational risk. The cluster needed a **single
source of truth** where Git *is* the desired state and the cluster continuously
matches it.

## What I set up

I deployed and operate **ArgoCD** on EKS to bring cluster configuration under GitOps:

- ArgoCD **watches a Git repository and automatically syncs** changes into the
  cluster (`syncPolicy.automated` enabled), so what's running always matches what's
  committed.
- Each managed component is an ArgoCD **Application** with automated sync — for
  example, the Kyverno security policies are delivered this way, so the cluster's
  guardrails are themselves version-controlled and self-healing.
- This eliminates manual `kubectl` drift: a change is made by committing to Git, not
  by touching the cluster directly, and every sync is recorded with the exact Git
  revision it deployed — a full audit trail of what changed, when, and from which
  commit.

> The GitOps configuration repository is shared team infrastructure; I set up and
> operate the ArgoCD layer that consumes it and reconciles it onto the cluster.

## Integration with Kyverno

I integrated ArgoCD with the **Kyverno** guardrails so the two work together rather
than against each other: ArgoCD continuously applies the desired state, and Kyverno
ensures nothing that gets applied violates the deletion-protection policies. The
pipeline can move fast *and* stay safe — see
[19-kyverno-policy](../19-kyverno-policy).

## Operating it

Part of owning ArgoCD is keeping the control plane healthy — the sync engine
(application-controller), repo-server, and applicationset-controller all have to be
running for deployments to reconcile. When a component degrades, reconciliation
stops, so operating ArgoCD means monitoring and recovering those pieces, not just the
initial install.

## What this demonstrates

Implementing GitOps as a delivery model, eliminating configuration drift, making Git
the audited source of truth, and integrating continuous delivery with policy-based
guardrails so automation stays compliant.

**Tech:** ArgoCD (Applications, automated sync), GitOps, Kubernetes, Kyverno, EKS, Git
