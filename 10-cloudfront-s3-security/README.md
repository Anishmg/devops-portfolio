# CloudFront + S3 Security Hardening (OAC)

## Problem

The platform serves a lot of static content — web app bundles, generated assets,
documents, casefiles — from S3 through CloudFront. Historically several of these S3
buckets were **publicly accessible**: anyone with the direct S3 URL could read them,
bypassing the CDN entirely. That's both a security exposure and a way to rack up
un-attributable S3 costs.

## Approach — Origin Access Control everywhere

I audited every S3 bucket and CloudFront distribution and migrated the CDN-served
buckets to **Origin Access Control (OAC)** — AWS's current method (replacing the
older OAI) for locking an S3 bucket so that *only* a specific CloudFront
distribution can read it.

For each bucket the end state is:

| | Before | After |
|---|---|---|
| Direct S3 URL | accessible | **403 blocked** |
| CloudFront URL | works | works |
| Public access block | off | **fully on** |
| Bucket policy | open/none | **CloudFront-only** |

The pattern applied per bucket:

1. Create an OAC and attach it to the CloudFront distribution's origin.
2. Replace the bucket policy with one that allows access **only** from that
   distribution (scoped by the distribution ARN).
3. Turn on S3 "Block all public access."
4. Verify: direct S3 URL returns 403, CloudFront URL still returns 200.

## Scale and extras

- Audited on the order of **50+ buckets and 12 distributions**, securing the
  CDN-backed ones and cleaning up test/orphan buckets and distributions.
- Fixed routing bugs uncovered during the audit — e.g. a CloudFront behavior for
  casefiles pointing at the wrong bucket, and a URL-rewrite function missing a path
  prefix — so hardening didn't break legitimate access.
- Added security response-headers policies where they were missing.

## What this demonstrates

Security auditing at scale, correct use of OAC over the deprecated OAI, careful
change management (verifying every migration didn't break real traffic), and CDN
routing/edge-function debugging.

**Tech:** AWS S3, CloudFront, OAC, bucket policies, CloudFront Functions
