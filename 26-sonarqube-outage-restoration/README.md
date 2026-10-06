# SonarQube — Diagnosing a 14-Day Silent Outage

## Problem

SonarQube provides code-quality scanning for the same pipeline that covers the
organisation's 276 repositories. It was running, yet **every scan in CI had been
failing for 14 days** — and because the scan step does not block the build,
**nothing alerted anyone**.

## What had happened

The server was being rebuilt so that every resource would carry a mandatory
cost-allocation tag from creation. The rebuild stalled for four days: an
organisation-level policy blocked instance launches that did not carry the tag at
the moment of creation. When the new instance finally came up, two steps were missed:

1. **DNS still pointed at the old load balancer**, not the new one.
2. **The new instance was never registered in the load balancer's target group**, so
   the new balancer had nothing to send traffic to.

SonarQube was running, but unreachable.

## Restoring it

- Updated DNS to the new load balancer and registered the instance — target health
  went to healthy.
- Confirmed the service answered over HTTPS, then ran a **canary workflow** and
  confirmed scans were passing across all 276 repositories again.
- Verified the tag on all 20 resources in the stack and confirmed from CloudTrail
  that each had been created *with* it, not patched afterwards.
- Stored the service credentials in Secrets Manager.

## The admin-password problem

The admin password was not recorded anywhere, and every reset attempt failed. The
cause was how the password hash was being generated: SonarQube hashes with PBKDF2,
and the **salt has to be base64-decoded into raw bytes before hashing** — the earlier
attempts hashed the text of the salt. Generating the hash correctly and writing it
to the database restored admin access, and the credentials went into Secrets Manager
the same way.

Then the loose ends: set the server's base URL (which fixed an OAuth HTTPS warning)
and checked the CI token — valid, and with no expiry.

## What I took from it

A failing check that doesn't fail the build is invisible. The remaining gap is a
health check on the service itself, so the next outage is noticed in minutes, not
weeks.

## What this demonstrates

Systematic root-cause analysis across DNS, load balancing and policy; a careful
credential reset by understanding the hashing scheme rather than guessing; and
verifying the end state with evidence instead of assuming it.

**Tech:** SonarQube, EC2, ALB / target groups, RDS, DNS, Secrets Manager, CloudTrail
