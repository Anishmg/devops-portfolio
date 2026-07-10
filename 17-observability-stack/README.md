# Observability Stack — Prometheus, Grafana, Loki

## Problem

A multi-tenant EKS platform running ~100 nodes and hundreds of workloads is
un-operable without observability. When something breaks, you need metrics (what's
the CPU/memory/pod state), logs (what did the service actually say), and dashboards
to make sense of it. None of that exists by default — it has to be deployed, tuned,
and operated.

## What I set up

I deployed and operate the observability stack on EKS, in a dedicated monitoring
namespace, via the **kube-prometheus-stack** Helm chart plus Loki:

- **Prometheus** — cluster-wide metrics collection, configured with **30-day
  retention** on a **50 Gi** persistent volume (EFS-backed), the admin API enabled,
  and **custom additional scrape configs** (via a secret) for targets beyond the
  defaults.
- **Grafana** — dashboards for visualizing everything, with persistent storage
  (EFS) and Traefik ingress so it's reachable internally.
- **kube-state-metrics** + **node-exporter** — node-exporter runs as a DaemonSet,
  one pod per node across the entire ~100-node fleet, exposing CPU/memory/disk/
  network metrics (on a custom port to avoid a conflict).
- **Loki + Promtail** — centralized log aggregation, with Promtail as a DaemonSet on
  every node shipping container logs into Loki, so troubleshooting is a single query
  instead of `kubectl logs` across dozens of pods.

## Tuning decisions that mattered

- **30d/50Gi retention on EFS** — enough history to investigate week-over-week
  trends and past incidents, on shared storage that survives pod rescheduling.
- **Custom scrape configs** — the platform has targets the default chart doesn't
  know about, wired in through an additional-scrape-configs secret rather than
  forking the chart.
- **Node-exporter port moved** — the default port collided with another workload, so
  it's remapped; a small but real operational detail that keeps metrics flowing on
  every node.

## Custom dashboards for real teams

Beyond the stack itself, I built targeted Grafana dashboards for specific teams —
for example, a dashboard for the Airflow team showing active DAG pod identities and
resource age, and dashboards for the self-managed MongoDB EC2 instances. I also
provided integrated live log views (via Loki) so engineers can read pod logs without
needing cluster access.

This observability stack is also what made my cost and reliability work possible —
the Prometheus metrics are how I could confirm that removing the duplicate CloudWatch
ContainerInsights addon lost no real telemetry (see
[02-eks-cost-optimization](../02-eks-cost-optimization)).

## What this demonstrates

Deploying and operating a production observability stack at scale (~100 nodes),
Helm-based platform management with real tuning (retention, storage, scrape configs),
custom dashboarding for actual teams, and centralized logging — the foundation
everything else (incident response, cost work) is built on.

**Tech:** Prometheus, Grafana, Loki, Promtail, kube-state-metrics, node-exporter,
Helm, EFS, Traefik, EKS
