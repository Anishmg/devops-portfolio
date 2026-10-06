# GitHub Organisation Governance — Access, 2FA, Audit and Offboarding

## Problem

A growing engineering organisation, with contractors and interns coming and going,
had accumulated access the usual way: granted when needed, rarely reviewed, never
removed. The organisation needed rules that were enforced by the platform rather than
by people remembering.

## What I put in place

- **Two-factor authentication enforced for the whole organisation**, and checked
  before anyone is added. Unused paid seats were removed at the same time.
- **A read-only base permission.** Everyone can read; write access is granted per
  repository, through teams, on request — not by default.
- **A repeatable access audit.** A script lists organisation owners, outside
  collaborators, members without 2FA, team membership and repository coverage, and
  who holds admin or write access on each repository. The output is a set of report
  files that can be compared quarter to quarter.
- **Outside collaborators are reviewed individually**, with what they can reach and
  why.
- **A documented offboarding procedure**, recorded step by step on a ticket, covering
  every system a leaver might hold access to — source control (both organisations),
  the workspace account, the workflow engine, DNS, the code scanner and the
  observability tools — with credentials rotated or reset where a shared one existed.

## A hardened organisation for an intern programme

Interns needed source control, a small database and AI tooling — and no route to
production. I built a **separate organisation** with the same security baseline:

- 2FA required, read-only base permission
- members cannot create or delete repositories, change visibility, fork private
  repositories or invite outside collaborators
- secret scanning with **push protection**, and dependency alerts, on by default
- third-party application access restricted to administrator-approved apps
- **spending budgets set to zero with hard stops** for every metered feature, so any
  overage pauses the service instead of billing silently
- branch protection on the main branch: pull request required, one approval,
  stale approvals dismissed, no force-push, enforced for administrators too

Database access for the programme is a **read-only user on a single dummy
collection**, through a custom role, so adding anything else needs an administrator
action that shows in the audit trail.

## Design decisions

- **Enforce, don't ask.** 2FA and base permission are platform settings.
- **Make the audit cheap to repeat.** A script, not a spreadsheet, so doing it again
  next quarter costs minutes.
- **Isolate rather than restrict.** A separate organisation for interns is simpler and
  safer than carving exceptions into the main one.
- **Name the trade-offs.** Shared accounts for the programme's AI tooling give no
  per-person audit trail; that is recorded rather than hidden.

## What this demonstrates

Access governance as engineering: enforced controls, a repeatable audit, a defined
offboarding process, and an isolated environment designed for least privilege.

**Tech:** GitHub (organisation settings, teams, branch protection, secret scanning),
GitHub CLI and API, shell scripting, MongoDB roles, Google Workspace
