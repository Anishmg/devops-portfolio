# MongoDB Access via PAM (Privileged Access Management)

## Problem

Engineers were connecting to production MongoDB **directly from their own machines**
using MongoDB Compass or the CLI. That meant no centralized access control, no
session recording, no audit trail of who accessed what, and no credential rotation.
For databases holding business-critical data, that's a governance gap.

The goal: route **all** MongoDB access through **Arcon PAM**, so every session is
authenticated, authorized, recorded, and auditable — while still giving engineers
the GUI (Compass) experience they rely on.

> This was a cross-team effort led by the Cyber Security team. My role was the
> infrastructure side: provisioning and configuring the servers and access path that
> made PAM integration work.

## The core challenge

MongoDB Compass doesn't natively integrate with PAM — PAM can't launch or govern a
Compass session directly. So a straight "PAM in front of Compass" approach wasn't
possible. We had to find an architecture that let PAM govern access while preserving
the GUI.

## Approach — a Windows RDP jump host behind PAM

After evaluating a Linux CLI-only bastion (rejected — the team needs the GUI), the
working design was:

1. **A Windows RDP jump server** with MongoDB Compass installed, provisioned with a
   dedicated security group and an Elastic IP.
2. **PAM governs the RDP session**, not Compass directly — engineers authenticate
   through PAM to reach the jump host, and from there use Compass to connect to the
   databases. All access is now funneled through one governed, recorded entry point.
3. **Enough concurrent capacity** — I added RDS CALs and raised the session limit so
   the jump host could support the full team (30+ users onboarded), and verified
   MongoDB connectivity for all of them.

On the infrastructure side I provisioned the jump host, installed the tooling,
prepared the user set for onboarding, and coordinated the security-group and access
changes so the databases would accept connections only through the governed path.

## What this demonstrates

Contributing infrastructure to a security/governance initiative, working within a
real constraint (Compass ≠ PAM-native) to find a workable architecture, and
provisioning multi-user access capacity — moving direct, unaudited DB access to a
governed, recorded model.

**Tech:** Arcon PAM, Windows RDP jump host, MongoDB Compass, AWS EC2, Security
Groups, Elastic IP
