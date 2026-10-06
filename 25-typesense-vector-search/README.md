# Typesense Vector Search — 900k-Document Migration and Tuning

## Problem

A semantic-search collection of about **900,000 documents** (17 fields, 1,536-
dimension embeddings) backs email case-file retrieval. Upserts had become slow, and
the server was holding about **60 GB** of memory.

## Approach

I did not experiment on production. I built **parallel test collections that
replicated the production schema exactly**, so each HNSW (approximate nearest-
neighbour) configuration could be benchmarked in isolation without any production
risk. Once I had parameters I trusted, I migrated the live collection to them.

## The migration

- **Zero-downtime swap** of the collection to the tuned parameters.
- A **documented rollback path**, and an **AMI snapshot** of the host taken first as
  insurance.
- A host restart afterwards to clear accumulated **memory fragmentation**, which on
  its own recovered about 39 GB of RAM.
- Cleanup of every test collection and stale AMI, so the work didn't leave new waste
  behind.

## Result

| | Before | After |
|---|---|---|
| Server memory | ~60 GB | **~21 GB** |
| Search latency | — | **~13 ms** |
| Production downtime | — | **none** |

## Related: right-sizing the managed cluster

Separately, the hosted Typesense Cloud cluster was provisioned at 256 GB of RAM. After
analysing it, I reduced it to **32 GB**, saving about **$13,500 a year**.

## What this demonstrates

Benchmarking safely before touching production, tuning a vector index with
measurements, executing a zero-downtime migration with a rollback path, and
following through on cost.

**Tech:** Typesense, HNSW vector search, EC2, AMI snapshots, capacity analysis
