# MongoDB Reliability & Incident Response

A series of production incidents on the platform's self-managed MongoDB fleet, and
the fixes and safeguards I put in place. This is the SRE core of my work: diagnosing
failures under pressure and making them not happen again.

---

## Incident 1 — Recurring out-of-memory crashes

**Symptom:** A production MongoDB instance kept crashing; the OS was OOM-killing
`mongod`.

**Diagnosis:** The instance was undersized (t3.medium, ~3.7 GB RAM) for its
workload. During heavy ETL periods, WiredTiger cache plus connection overhead
consumed essentially all RAM. On one client's instance, a security agent's manifest
download ballooned a process from ~110 MB to ~980 MB and tipped the box over — I
pulled the kernel OOM log lines from CloudWatch as evidence before the short log
retention expired.

**Fix:**
- Upgraded the instance (t3.medium → t3.large, ~7.6 GB) and added swap as a safety
  margin.
- Upgraded MongoDB 7.0 → 8.0 on the relevant instances.
- Extended CloudWatch log retention so future incidents remain diagnosable.

---

## Incident 2 — Connection-pool leak (the big one)

**Symptom:** A MongoDB instance sat at ~89% memory with **~11,700 connections**,
most of them idle. Memory pressure was causing intermittent timeouts across
services.

**Diagnosis:** I scanned every pod's live TCP connections (`/proc/net/tcp`) to find
the source and traced ~10,500 established connections back to a single service. The
root cause was a MongoDB driver misconfiguration: `minPoolSize` was set high while
`maxIdleTimeMS` was expected to close idle connections — but `minPoolSize` keeps a
floor of connections open permanently, so idle connections never dropped.

**Fix:** Recommended `maxPoolSize` and `minPoolSize: 0` corrections to the owning
service. After the fix:
- Total connections **~11,700 → ~3,900**
- Server memory **29 GB → 20 GB**

I also compiled a prioritized (P0/P1/P2) list of every service connecting without a
bounded pool or an `appName`, so the remaining offenders could be fixed
systematically.

---

## Safeguard — Monit auto-restart across the fleet

To stop a single crash from becoming downtime, I installed and configured **Monit**
on all four production MongoDB instances:

- Detects a down `mongod` within ~60 seconds and restarts it automatically.
- Emails all on-call recipients on every state change.
- Exposes a simple status UI.

This turned "MongoDB is down, someone needs to SSH in" into a self-healing event
with a paper trail.

---

## What this demonstrates

Systematic root-cause analysis (kernel logs, live socket inspection, driver
internals), capacity right-sizing, and building safeguards so incidents don't recur.

**Tech:** MongoDB, WiredTiger, Linux (`/proc`, OOM killer), Monit, AWS EC2,
CloudWatch
