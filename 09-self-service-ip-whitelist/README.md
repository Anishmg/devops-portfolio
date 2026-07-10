# Self-Service IP Whitelisting (GitHub Actions)

## Problem

The team's self-managed MongoDB (and Typesense) instances are locked down by
security group to specific IPs. Engineers work from changing IPs (home, office,
travel), so someone — usually me — was constantly editing security groups by hand to
add or update access. It was a repetitive, error-prone bottleneck, and manual SG
edits are exactly how stale, untracked rules pile up.

## Approach — a governed self-service workflow

I built a **GitHub Actions workflow** that lets any authorized engineer add or
remove their own IP across the MongoDB instances, safely, without touching the AWS
console:

- **Dropdown of known users.** The workflow takes the engineer's email from a
  fixed dropdown (not free text), so every rule is tagged with a real owner and
  typos can't create orphan rules.
- **Per-instance or all-instance targeting.** The engineer picks which instances to
  whitelist on, or "all."
- **Input validation.** The IP is validated (format and octet range) before any AWS
  call is made.
- **Keyless auth.** The workflow assumes an AWS role via **OIDC** — no static
  credentials stored in GitHub.

## The interesting engineering: three problems I had to solve

1. **Replace, don't accumulate.** When an engineer's IP changes, naively adding a
   new rule leaves the old one behind forever. The workflow first searches all of an
   instance's security groups for an existing rule matching that engineer's email,
   removes the old IP, and adds the new one — so each person has exactly one rule,
   always current.

2. **The 60-rule security-group limit.** AWS caps inbound rules per security group
   (default 60). On busy instances this fills up. The workflow tracks each SG's rule
   count and, when they're all near the limit, **automatically creates a new
   "overflow" security group, tags it, and attaches it to the instance** — then adds
   the rule there. Whitelisting never fails just because a group is full.

3. **Don't touch the wrong groups.** Instances have SGs that aren't for user access
   (e.g. a monitoring/Prometheus SG). The config hardcodes exactly which SGs are
   valid targets for user IPs per instance, so automation never accidentally opens a
   rule on an infrastructure security group.

Every run posts a summary (added / replaced / skipped / failed, and any new SG
created) to the GitHub job output for a clean audit trail.

A parallel workflow does the same for Typesense (different ports, smaller user set).

## What this demonstrates

Turning a manual toil task into safe self-service, real AWS API automation with edge
cases handled (rule replacement, the SG rule-count limit, target-group safety), and
security-conscious design (owner tagging, input validation, OIDC, audit summaries).

**Tech:** GitHub Actions, AWS EC2 Security Groups, AWS CLI, OIDC, Bash

> *This work also fed directly into a broader security cleanup: removing 1000+ stale,
> name-based SG rules and deleting empty security groups across all instances.*
