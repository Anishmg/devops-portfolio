# Infrastructure as Code — Terraform Monorepo

## Problem

The platform's AWS infrastructure spans multiple clients and two regions. Managing
that by hand in the console is slow, error-prone, and impossible to audit. Every
environment needed the same building blocks (networking, clusters, databases,
CDNs, IAM) provisioned consistently and repeatably.

## Approach

I built and maintained a Terraform monorepo structured as a library of reusable
**modules** plus thin per-environment **deployments** that compose them. Terragrunt
keeps the deployments DRY and manages remote state.

```
modules/aws/
  vpc/base/                     network foundation (subnets, route tables, NAT)
  eks/cluster/                  EKS control plane, node groups
  eks/karpenter-resources/      Karpenter provisioners for autoscaling
  eks/aws-load-balancer-controller-iam/
  eks/service-account/          IRSA (IAM Roles for Service Accounts)
  rds/postgres/                 managed PostgreSQL
  elasticache/redis/            managed Redis
  docdb/cluster/                DocumentDB
  ec2/mongodb/                  self-managed MongoDB instances
  ec2/typesense/                self-managed Typesense search
  ecs/cluster/ + fargate-service/
  cloudfront/distribution/ + url-rewrite-function/
  lambda-edge/spa-routing/      SPA routing at the edge
  acm/                          TLS certificates
  s3/bucket/
  mwaa/environment/             managed Airflow
  iam/github-actions-oidc/      keyless CI/CD auth
  iam/eks-irsa/ + ec2-role/ + lambda-edge-role/

deployments/
  client-a/                     one client's full stack
  client-b/                     another client's full stack
```

## Key design decisions

- **Modules over copy-paste.** Each AWS concern is a single module with typed
  variables and outputs. A new client environment is assembled from the same
  modules rather than duplicated Terraform.
- **Keyless CI/CD.** The `iam/github-actions-oidc` module wires GitHub Actions to
  AWS using OIDC federation, so no long-lived AWS access keys are stored as
  secrets anywhere — pipelines assume a scoped role at runtime.
- **IRSA everywhere.** Workloads on EKS get AWS permissions through per-service-
  account IAM roles (least privilege) instead of node-wide credentials.
- **Single source of truth for Airflow.** The Airflow Helm values live in this
  repo and are treated as authoritative — configuration drift gets reconciled back
  into Terraform.

## What this demonstrates

Reusable module design, multi-environment/multi-client provisioning, remote state
management with Terragrunt, and secure-by-default CI/CD via OIDC and IRSA.

**Tech:** Terraform, Terragrunt, AWS (VPC, EKS, RDS, ElastiCache, DocumentDB, ECS,
CloudFront, Lambda@Edge, ACM, S3, MWAA, IAM/OIDC/IRSA)
