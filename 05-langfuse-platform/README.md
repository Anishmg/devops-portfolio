# Langfuse — LLM Observability Platform (Setup & Operation)

## Context

Langfuse is the platform's **LLM-observability system** — it captures a trace of
every AI interaction (prompts, responses, token usage, latency, cost) so the AI
teams can see what their models are actually doing in production. I set up and
operate this system end to end; there's no application code here, it's entirely an
infrastructure/platform deployment I own.

## What I built

Langfuse v3 is not a single container — it's a stack of stateful backends that all
have to be provisioned and wired together correctly. I deployed the full stack on
EKS for each environment that needs it:

- **Langfuse web + worker** deployments (the app tier and the async trace-ingestion
  workers).
- **ClickHouse** — the columnar store that holds the high-volume trace data, running
  as a stateful workload with its own persistent volume.
- **Redis** — the queue/cache layer (BullMQ) that buffers trace ingestion.
- **PostgreSQL on RDS** — the metadata store, moved onto managed RDS with 50 GB
  storage for durability.
- **S3** — object storage for large payloads and batch exports.
- **IRSA** — an IAM-Roles-for-Service-Accounts binding so the pods get exactly the
  AWS permissions they need (S3) and nothing more.

I deployed this across multiple clusters/environments (e.g. the main platform and a
separate client cluster), each with its own isolated backends, and set up
**ClickHouse daily backups via AWS Backup**.

## Migration

I also handled the **v2 → v3 migration**, which wasn't a simple upgrade —
v3 changed the architecture (introducing ClickHouse and the worker tier) and even
the API-key hashing algorithm. I migrated the data, stood up the new backends, and
resolved the key-hashing incompatibility so existing integrations kept working after
the cutover.

## Securing it

Langfuse holds sensitive trace data, so I locked it down:
- Restricted access to whitelisted IPs via a WAF rule, without affecting other
  services sharing the ingress.
- Removed hardcoded credentials from the host, enforced IMDSv2, and set up a daily
  log backup.

## Operating it — the recovery story

Because I run this system, I also handle its incidents. The most significant: trace
ingestion stopped completely, and I traced it through the pipeline to **three
compounding failures** — ClickHouse disk almost full (~1 MB free of 20 GB),
hundreds of corrupted Redis/BullMQ queue keys blocking the workers, and ClickHouse
throttled to a single CPU core. I fixed all three (expanded the PVC 20→50 GB, raised
CPU 1→2 cores, deleted 442 corrupted keys, restarted the deployments) and restored
all **16 processing queues**. I later also fixed the batch-export configuration,
which had never been set up with the correct env var names.

## What this demonstrates

Standing up and owning a multi-component stateful platform (ClickHouse + Redis +
RDS + S3 + workers) on Kubernetes, handling a non-trivial version migration,
securing it, and operating it through real incidents — full lifecycle ownership, not
just deployment.

**Tech:** Langfuse, ClickHouse, Redis / BullMQ, PostgreSQL (RDS), S3, Kubernetes
(IRSA, PVCs, resources), AWS Backup, WAF
