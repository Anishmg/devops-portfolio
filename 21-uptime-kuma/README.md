# Uptime Kuma — External Uptime Monitoring

## Problem

Internal metrics (Prometheus/Grafana) tell you what's happening *inside* the cluster,
but they don't answer the most basic question a user cares about: **"is the site
actually up and reachable right now?"** For that you need monitoring that checks
services the way a user would — from the outside, hitting the public endpoint. And
when something goes down, someone needs to be told immediately.

## What I set up

I deployed and operate **Uptime Kuma** on EKS as the platform's external
uptime/status monitoring:

- Continuously probes the platform's public endpoints and service URLs (HTTP checks)
  to confirm they're reachable and returning healthy responses.
- Tracks uptime percentage per service over time, so degradation and flapping are
  visible, not just hard-down events.
- Alerts when a monitored endpoint goes down, so problems are caught proactively
  rather than reported by users.

## How it complements the rest of the stack

Uptime Kuma sits alongside the Prometheus/Grafana/Loki stack but answers a different
question — it's the black-box, user's-eye view (is the endpoint up?) versus the
white-box, internal view (what are the pods and nodes doing?). Together they cover
both "the user can't reach the site" and "here's the internal reason why."

In practice this external view has directly surfaced real incidents — for example an
application service showing degraded uptime in Uptime Kuma was the first signal of a
pod crash-looping on OOM, which I then root-caused internally.

## What this demonstrates

Setting up black-box/synthetic uptime monitoring, proactive alerting, and
understanding the complementary roles of external vs internal monitoring in a
complete observability strategy.

**Tech:** Uptime Kuma, Kubernetes, HTTP health checks, alerting, EKS
