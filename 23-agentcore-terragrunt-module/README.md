# Terragrunt Module — A Full AgentCore Environment from One Line

## Problem

Each new AgentCore environment needed around sixteen resources created in the right
order, with the right names, tags and permissions. Doing it by hand was slow and
inconsistent, and a client environment in another AWS account meant doing it again
in a place where mistakes are more expensive.

## Approach

I wrote a single reusable Terraform module and drove it with **Terragrunt**.

Why Terragrunt rather than plain Terraform:

| Problem with plain Terraform | What Terragrunt does |
|---|---|
| Backend config repeated per environment | State key derived from the folder path |
| Environment name needed in several places | **One line** differs between environments |
| Module blocks copied per environment | One shared root configuration |
| A wrong state key can overwrite another environment | Keys are generated, never typed |

```
infra/
  root.hcl                  shared backend and provider config
  modules/agentcore-env/    the reusable module
  environments/
    <env-a>/terragrunt.hcl  env_name = "..."
    <env-b>/terragrunt.hcl
```

A new environment is a copy of an existing folder with one value changed, then
`terragrunt apply`.

## What the module creates (16 resources)

Container registry and its lifecycle policy; the AgentCore runtime; the Code
Interpreter; the EventBridge schedule group; the automation Lambda with its role,
policy and log group; the Secrets Manager entry holding roughly ninety configuration
keys; an optional PostgreSQL instance; and a versioned, encrypted state bucket.

## Key design decisions

- **Shared wildcard IAM policies, added once.** Per-environment inline policies would
  accumulate on the shared roles and eventually hit AWS's inline-policy limits. One
  policy scoped by name prefix covers every environment, and its size never grows.
- **Mandatory tags on everything.** The account blocks creation of untagged
  resources, so tagging is part of the module, not an afterthought.
- **Production left outside the module on purpose.** Importing a live environment is
  a separate, riskier job; the module is used for new environments only.

## What testing found

A full apply-and-destroy cycle on a throwaway environment exposed four blockers:

1. **The runtime fails if its registry is empty** — AWS pulls the image immediately.
   Fixed with a two-step apply and an image copy in between.
2. **Destroy did not delete the runtime or Code Interpreter**, because the resources
   that create them have no destroy step. Added destroy provisioners.
3. **Registry deletion failed when images existed.** Set force-delete.
4. **Secret deletion left a 30-day window** that broke re-creating the environment.
   Set the recovery window to zero.

After the fixes, all sixteen resources came up healthy and were cleanly deleted.

## What this demonstrates

Turning a manual runbook into reusable infrastructure code, choosing the right tool
for the problem, designing shared IAM that scales, and **testing the destroy path** —
the half of infrastructure code that is usually never exercised.

**Tech:** Terraform, Terragrunt, AWS (Bedrock AgentCore, Lambda, EventBridge, IAM,
ECR, Secrets Manager, RDS, S3)
