# Bedrock Per-User Cost Attribution (FinOps)

## Problem

The platform's AI features run on **Amazon Bedrock** (multiple Claude models). The
bill was significant and growing, but there was no visibility into **who** was
spending it — which team, which API key, which model. Without attribution, you can't
control cost or catch misuse.

## Approach — CUR 2.0 with per-principal tracking

I set up cost attribution using the **AWS Cost and Usage Report (CUR 2.0)** with IAM
principal tracking enabled, so every dollar of Bedrock spend could be traced to the
specific API key / user that incurred it:

1. Created a **CUR 2.0 data export** with IAM-principal attribution turned on,
   landing in a dedicated S3 bucket.
2. **Tagged each Bedrock API-key IAM user** by team (dev, data-science, benchmark)
   so costs roll up meaningfully.
3. Parsed the CUR files to produce **per-key, per-model** cost reports — exact token
   counts (input, output, cache read/write), the rate per million tokens, and the
   resulting cost, reconciled to the cent against the bill.

## Findings that mattered

The attribution immediately surfaced things that were invisible before:

- A large share of spend was coming from an **untagged, unrestricted** key with no
  clear owner — the biggest single line item.
- **Non-Claude model usage** (someone calling models they shouldn't) showed up as a
  distinct cost.
- Clear per-team breakdowns that let the spend actually be managed.

## Follow-on: guardrails

Beyond reporting, I added **IAM policies restricting which models each key can
invoke** (e.g. one key limited to a single Sonnet model, another to Sonnet + Haiku),
and debugged the cross-region inference-profile permissions so the allowed models
still worked while everything else was denied. Attribution plus restriction turned
an opaque, uncontrolled bill into a governed one.

## What this demonstrates

FinOps for AI workloads: CUR 2.0 setup, IAM-principal cost attribution, token-level
reconciliation, and translating findings into IAM guardrails that actually control
spend.

**Tech:** AWS Bedrock, Cost & Usage Reports (CUR 2.0), IAM (policies, tagging), S3,
cost analysis
