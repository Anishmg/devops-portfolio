# MongoDB Backup System

## Problem

The platform runs several self-managed MongoDB instances (production, non-prod, and
several ETL databases) holding business-critical data. There was no consistent,
automated, credential-safe backup process, and running dumps directly on the DB
servers risked starving production of disk, CPU, and RAM.

## Approach

I built a set of backup scripts that all run from a **dedicated backup EC2
instance** — never on the database servers themselves — so backup load never
touches production. Every script follows the same flow:

```
fetch credentials from Secrets Manager
  → mongodump the target database
    → compress to .zip
      → upload to S3 under {year-month}/{instance}/{database}/
        → delete local files
          → email an HTML report via SES
```

## Key design decisions

- **No hardcoded credentials.** Every script pulls host, user, password, S3 bucket,
  and SMTP settings from **AWS Secrets Manager** at runtime. Nothing sensitive lives
  in the code or in the repo.
- **Backups run off-box.** A separate backup instance means production databases
  are never slowed by a dump.
- **Large collections handled deliberately.** One ETL database had a ~473 GB
  `mail_archive` collection that made a full nightly dump impractical, so that
  collection is excluded from the daily job and backed up on its own **weekly**
  schedule instead.
- **Staggered schedules** so no two heavy dumps overlap:

  | Job | Schedule (UTC) |
  |---|---|
  | Application Production | Daily 14:30 |
  | Application Non-Prod | Daily 15:30 |
  | ETL Production | Daily 18:30 |
  | ETL Data | Daily 21:30 |
  | ETL Dev (excl. large collection) | Daily 23:30 |
  | ETL Dev large collection | Weekly, Saturday 02:00 |

- **Every run reports.** Success or failure, an HTML email goes out so a silent
  failure can't go unnoticed.

## Sanitized example

See [`backup-example.sh`](./backup-example.sh) for a representative, fully
genericized version of one script — credentials read from Secrets Manager,
dump → zip → S3 → email, with placeholders throughout.

## What this demonstrates

Secrets-managed automation, production-safe operational design, S3 lifecycle
organization, SES alerting, and pragmatic handling of very large datasets.

**Tech:** MongoDB (`mongodump`), AWS Secrets Manager, S3, SES, Bash, cron
