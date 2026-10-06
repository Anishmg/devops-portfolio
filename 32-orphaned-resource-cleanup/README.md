# Cleaning Up Orphaned Resources Outside the Primary Region

## Problem

The platform runs in a single primary region, but older experiments had left
resources behind in other regions: runtimes, functions, tables, buckets and logs from
platforms that were no longer in use. Some were costing money; some were a risk. The
challenge was deleting them **without deleting anything still alive** — the same class
of mistake that had caused production outages before (see
[27-ecr-lifecycle-outages](../27-ecr-lifecycle-outages)).

## Approach — verify behaviour, not just names

For every candidate I checked how it was actually used, from several angles:

- **Metrics.** AgentCore runtimes: zero invocations over 90 days. A scheduled Lambda
  had run about 43,000 times in 30 days — once a minute — finding nothing to do, pure
  cost with no function. Gateway Lambdas: zero invocations in 30 days.
- **Audit trail.** A queue created months earlier had zero messages and zero events,
  ever.
- **References.** Two buckets were first held back because their policies pointed at
  CloudFront distributions. Checking showed both distributions no longer existed, so
  the policies were orphaned and the buckets were safe to remove.

## Doing it safely

- **Backups before deletion** — Lambda deployment packages, rule and target
  definitions, runtime configurations and table exports.
- **Order matters.** The schedule rule's targets were removed first and the rule second,
  so nothing kept firing at a function that was gone.
- **Approval from the people who owned the platforms**, recorded on the ticket.

## What was removed

Two batches, **40 resources** across several regions:

| Batch | Resources |
|---|---|
| 1 (14) | 3 AgentCore runtimes, 3 Lambda functions, 1 EventBridge rule, 7 S3 buckets |
| 2 (26) | 4 container repositories, 4 DynamoDB tables, 2 CodeBuild projects, 13 log groups, an unused queue, and 2 expired certificates |

**Security finding.** Two of the Lambda functions had **public Function URLs with no
authentication**. Deleting them closed two internet-facing endpoints that nobody was
using.

Separately, I removed an abandoned proof-of-concept environment — a Kubernetes
cluster with nodes, a NAT gateway, orphaned volumes and a VPC — that had been running
for about two months at roughly **$220 a month**.

## What deliberately stayed

I finished by documenting everything that remains outside the primary region and
**why it has to**: CloudFront, its WAF rules, edge functions and certificates, global
DNS and the cost-reporting bucket are all required to live in one specific region by
AWS itself. A client environment stays in its own region. An inventory of justified
residuals means the next audit doesn't re-ask the same questions.

## What this demonstrates

Safe deletion at scale: evidence-based decisions, backups, ordering, recorded approval,
and finishing with documentation so the work stays done.

**Tech:** AWS (Lambda, DynamoDB, S3, ECR, CodeBuild, EventBridge, CloudWatch,
CloudTrail, CloudFront), cost analysis
