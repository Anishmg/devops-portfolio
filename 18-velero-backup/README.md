# Velero — Automated Kubernetes Backup & DR

## Problem

A large population of stateful user workloads (400+ user workspace pods, each with
its own PersistentVolume) means a lot of data lives in the cluster. If a PVC or PV is
deleted — accidentally or otherwise — that data is gone unless there's a backup. The
platform needed automated, scheduled, restorable backups of persistent volumes.

## What I set up

I deployed and operate **Velero** on EKS for Kubernetes-native backup and disaster
recovery, backed by EBS snapshots:

- **Automated daily EBS snapshots** of all PVCs in the application namespace,
  scheduled overnight (00:00 IST) with a **3-day retention** window.
- A **`pvc-auto-labeler` CronJob** that runs on a schedule to tag newly-created PVCs
  so they're automatically included in the backup plan — so backups don't silently
  miss volumes created after the plan was set up. (This is visible running in the
  cluster as the recurring `pvc-auto-labeler` completed jobs.)

## Why the auto-labeler matters

The subtle failure mode with volume backups is *coverage*: a backup plan that
targets a static list of volumes will quietly stop protecting anything created after
it was written. By auto-labeling new PVCs on a schedule, every new user volume is
enrolled in backups automatically — closing that gap without manual intervention.

## Connected DR work

This backup capability is what made real disaster recovery possible. When 53 user
PVCs were accidentally deleted on a client cluster, having snapshot-based backups
(and the reclaim-policy discipline around them) is what allowed a full restore of all
53 users — see [16-disaster-recovery-pvc](../16-disaster-recovery-pvc).

## What this demonstrates

Setting up Kubernetes-native backup/DR at scale, closing the backup-coverage gap
with automated PVC labeling, and connecting backup strategy to proven restore
outcomes.

**Tech:** Velero, AWS EBS snapshots, AWS Backup, Kubernetes (PVC/PV, CronJobs), EKS
