# Disaster Recovery — Restoring 53 Deleted User Volumes

## Problem

A set of **53 user PersistentVolumeClaims (PVCs)** on a client cluster were
accidentally deleted. Each PVC held a user's workspace data. This is exactly the kind
of event that tests whether "we have backups" actually means "we can restore."

## Approach — restore from snapshots, safely, one at a time

### 1. Stop the bleeding
The immediate risk was *more* data loss: any still-bound volume could be reclaimed if
its deployment cycled. I patched the reclaim policy from `Delete` → `Retain` on the
PersistentVolumes for the users who were still running, so their data couldn't
disappear while I worked.

### 2. Find the backups
The volumes were backed by scheduled EBS snapshots (via the cluster's snapshot
tooling). I identified the correct most-recent snapshot per user by sorting
snapshots by start time and matching them to the impacted volume IDs.

### 3. Restore methodically
For the not-running users, I restored each PVC from its snapshot one by one,
cross-referencing volume IDs against the official impacted-user list so nobody was
missed. I proved the procedure end-to-end on a single user first, then scripted it.

### 4. Handle the stuck cases
Several PVs got stuck in `Terminating`; I cleared them by removing the finalizers.
A few edge-case users (deleted PVs, pending states) I restored individually.

## Result

**All 53 impacted users accounted for and restorable**, with reusable restore
scripts (`restore_user_pvcs.sh`, `sync_user_data.sh`) produced so the same event
could be handled quickly in future. I also reconciled the cluster against the
official list and flagged extra users present in the cluster but not on the list.

## What this demonstrates

Real disaster-recovery execution under pressure: containing further loss first,
locating the right backups, validating the restore procedure before scaling it, and
handling the messy edge cases (stuck finalizers, deleted PVs) — then leaving behind
reusable tooling.

**Tech:** Kubernetes (PVC/PV, reclaim policies, finalizers), AWS EBS snapshots,
Bash
