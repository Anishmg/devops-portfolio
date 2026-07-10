# DevOps & SRE Portfolio — Anish M

A collection of infrastructure, reliability, and cost-optimization work I've done
as the DevOps / SRE owner of a multi-tenant, multi-region enterprise SaaS platform
running on AWS EKS.

Each folder is a self-contained write-up: the **problem**, **how I approached it**,
the **technical implementation**, and the **result**. All examples use placeholder
values — no credentials, internal hostnames, or client data.

> These write-ups describe infrastructure, platform, and deployment work I designed
> and operate. Where a repository's application source belongs to the development
> teams I supported, the write-up says so and documents only the infrastructure,
> automation, and deployment layer — which is my work.

## Projects

### Infrastructure & Platform
| # | Project | What it demonstrates |
|---|---------|----------------------|
| 01 | [Infrastructure as Code](./01-infrastructure-as-code) | Terraform/Terragrunt monorepo — 15+ reusable AWS modules |
| 17 | [Observability Stack](./17-observability-stack) | Prometheus, Grafana, Loki at ~100-node scale |
| 20 | [ArgoCD GitOps](./20-argocd-gitops) | Git as source of truth, continuous sync, drift elimination |
| 19 | [Kyverno Policy-as-Code](./19-kyverno-policy) | Admission-control guardrails across 21 namespaces |
| 18 | [Velero Backup & DR](./18-velero-backup) | Automated PVC snapshots with auto-labeling |
| 21 | [Uptime Kuma](./21-uptime-kuma) | External/synthetic uptime monitoring + alerting |

### Reliability & Cost (SRE / FinOps)
| # | Project | What it demonstrates |
|---|---------|----------------------|
| 02 | [EKS Cost Optimization](./02-eks-cost-optimization) | Karpenter 125 to 82 nodes + CloudWatch 89% cut |
| 04 | [MongoDB Reliability](./04-mongodb-reliability) | OOM response, connection-leak debugging, auto-restart |
| 05 | [Langfuse Platform](./05-langfuse-platform) | Full LLM-observability stack: setup, migration, operation |
| 15 | [Bedrock Cost Attribution](./15-bedrock-cost-attribution) | Per-user LLM cost tracking via CUR 2.0 |
| 16 | [Disaster Recovery](./16-disaster-recovery-pvc) | Restoring 53 deleted user volumes from snapshots |

### Data & Backups
| # | Project | What it demonstrates |
|---|---------|----------------------|
| 03 | [MongoDB Backup System](./03-mongodb-backup-system) | Credential-safe automated backups to S3 with alerting |
| 12 | [MongoDB PAM Integration](./12-mongodb-pam-integration) | Governed DB access via a PAM jump host |

### Deployment Engineering
| # | Project | What it demonstrates |
|---|---------|----------------------|
| 07 | [Multi-Client Deployment](./07-multi-client-deployment) | Kustomize base + per-client overlays for core services |
| 08 | [Micro-Frontend Deployment](./08-microfrontend-deployment) | Helm + the build-time vs runtime env problem, solved |
| 06 | [Airflow on EKS](./06-airflow-eks-migration) | MWAA to self-managed Airflow with a custom image |
| 14 | [MCP Wrapper Deployment](./14-mcp-wrapper-deployment) | Secrets-driven multi-instance service deployment |
| 13 | [Mobile CI/CD](./13-mobile-cicd) | iOS + Android build, signing, and store deploy |

### Automation & Security
| # | Project | What it demonstrates |
|---|---------|----------------------|
| 09 | [Self-Service IP Whitelisting](./09-self-service-ip-whitelist) | GitHub Actions automation with SG-overflow handling |
| 10 | [CloudFront + S3 Security](./10-cloudfront-s3-security) | OAC hardening of public buckets behind a CDN |
| 11 | [Per-User Container Service](./11-per-user-container-service) | FastAPI service provisioning K8s pods per user |

## Core skills across this work

- **Cloud:** AWS (EKS, EC2, IAM, Lambda, S3, CloudFront, RDS, DocumentDB, ECS, SQS, Secrets Manager, CloudWatch, CUR, WAF, Backup), GCP
- **Kubernetes platform:** EKS, Helm, Kustomize, Karpenter, ArgoCD, Kyverno, Velero, KEDA
- **Observability:** Prometheus, Grafana, Loki, Uptime Kuma, Langfuse
- **IaC:** Terraform, Terragrunt
- **CI/CD:** GitHub Actions (OIDC), Jenkins
- **Databases:** MongoDB, PostgreSQL, ClickHouse, Redis
- **Practices:** Site Reliability Engineering, FinOps, IAM security governance, GitOps

## About

AWS DevOps & Site Reliability Engineer based in Chennai, India.
Reach me at anishmg22@gmail.com or on [LinkedIn](https://www.linkedin.com/in/anish-m-1184b2258/).
