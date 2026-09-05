# AS Bank Infrastructure

AWS infrastructure and platform automation for the AS Bank project.

AS Bank is a learning platform built with synthetic data. It is designed to exercise DevOps, DevSecOps, AWS, Kubernetes, platform engineering, and SRE practices against explicit availability, recovery, performance, security, and cost requirements.

This repository owns the AWS infrastructure, Terraform, environment lifecycle automation, and Terraform-managed Kubernetes platform bootstrap.

> This is a learning project. It does not process real customer or banking data and is not presented as production banking experience.

## Architecture

The platform uses one AWS account with separate infrastructure and state boundaries for persistent resources, dev, and prod.

```text
                         GitHub
                           |
                           | OIDC
                           v
                    GitHub Actions
                           |
                           v
                       Terraform
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
      Layer 0          Layer 1          Layer 2
     Persistent        Network           Cluster
          |                |                |
          |                |                +--> EKS
          |                |                +--> Karpenter
          |                |                +--> Argo CD
          |                |                +--> Kyverno
          |                |                +--> External Secrets
          |                |
          |                +--> VPC
          |                +--> Subnets
          |                +--> Route tables
          |                +--> Gateway endpoints
          |
          +--> Terraform state
          +--> ECR
          +--> GitHub OIDC
          +--> IAM roles
          +--> Route 53
          +--> Cognito
          +--> AWS Budgets

                           |
                           v
                        Layer 3
                          Data
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
          Customer       Account     Transaction
            RDS            RDS           RDS
```

Application workloads are deployed to EKS by Argo CD from the separate [`as-bank-gitops`](https://github.com/sai-pillalamarri/as-bank-gitops) repository.

GitHub Actions does not run `kubectl apply`.

## Repository Responsibilities

This repository manages:

- AWS account bootstrap resources
- Terraform remote state
- GitHub OIDC and IAM roles
- ECR repositories
- Route 53
- Cognito
- dev and prod VPCs
- EKS clusters
- Karpenter
- EKS Pod Identity
- External Secrets Operator
- Kyverno
- Argo CD bootstrap
- RDS PostgreSQL
- environment creation and teardown workflows
- Terraform validation, planning, and apply workflows
- operational scripts used by the infrastructure lifecycle

Application source code belongs in [`as-bank-app`](https://github.com/sai-pillalamarri/as-bank-app).

Kubernetes desired state belongs in [`as-bank-gitops`](https://github.com/sai-pillalamarri/as-bank-gitops).

## Terraform Layers

Infrastructure is split by lifecycle rather than kept in one Terraform state.

| Layer | Responsibility | Lifecycle |
| --- | --- | --- |
| **0 — Bootstrap** | State bucket, ECR, GitHub OIDC, IAM roles, Route 53, Cognito, Budgets | Persistent |
| **1 — Network** | VPCs, subnets, route tables, Internet Gateway, gateway endpoints | Persistent |
| **2 — Cluster** | EKS, nodes, Karpenter, NAT, paid interface endpoints, platform bootstrap | Created when needed |
| **3 — Data** | PostgreSQL databases and Secrets Manager credentials | Created when needed, snapshot before destroy |

Dev and prod use separate Terraform state.

This means destroying a dev cluster cannot accidentally destroy the prod cluster or persistent account-level resources.

## Why the Lifecycle Is Split

EKS, NAT Gateways, load balancers, databases, and PrivateLink endpoints cost money while they exist.

The project therefore separates resources that need to survive from resources that can be rebuilt.

```text
Persistent
    |
    +--> Terraform state
    +--> ECR images
    +--> DNS
    +--> IAM / OIDC
    +--> Cognito

Ephemeral
    |
    +--> EKS
    +--> worker nodes
    +--> NAT Gateway
    +--> paid interface endpoints
    +--> RDS
```

The environment is designed to be rebuilt from Terraform and Git rather than kept running continuously.

## Environment Lifecycle

Routine environment operations are triggered through GitHub Actions.

The Makefile provides a thin local wrapper:

```bash
make up ENV=dev
```

and:

```bash
make down ENV=dev
```

Prod must be named explicitly:

```bash
make up ENV=prod
make down ENV=prod
```

The workstation triggers the workflow. Terraform execution happens in CI using GitHub OIDC and environment-specific AWS roles.

There is no long-lived AWS access key used by the infrastructure pipeline.

## GitOps Boundary

Terraform and Argo CD deliberately have different ownership.

```text
Terraform
   |
   +--> AWS infrastructure
   +--> EKS
   +--> Argo CD installation
   +--> environment root Application

Argo CD
   |
   +--> platform desired state
   +--> application workloads
   +--> Kubernetes policies
   +--> environment configuration
```

Terraform bootstraps Argo CD.

After that, Argo CD reconciles Kubernetes desired state from [`as-bank-gitops`](https://github.com/sai-pillalamarri/as-bank-gitops).

This avoids having both Terraform and Argo CD manage the same Kubernetes resources.

## Kubernetes Platform

The EKS platform currently includes:

- Argo CD
- Karpenter
- External Secrets Operator
- Kyverno
- EKS Pod Identity
- Metrics Server
- VPC CNI NetworkPolicy enforcement
- Pod Security Admission

Dev Karpenter capacity uses Spot instances.

Prod is configured for On-Demand capacity.

## Security Controls

The infrastructure exercises several identity and workload security controls.

### Human access

```text
IAM user
   |
   +--> MFA
   |
   +--> aws login
   |
   +--> temporary credentials
   |
   +--> STS operator role
```

The project operator has no static IAM access keys.

### CI access

```text
GitHub Actions
      |
      v
 GitHub OIDC
      |
      v
environment IAM role
      |
      v
     AWS
```

Infrastructure plan and apply permissions are separated.

### Workload access

```text
Kubernetes Pod
      |
      v
EKS Pod Identity
      |
      v
least-privilege IAM role
      |
      v
AWS service
```

AWS permissions are not inherited from worker nodes.

### Secrets

Application secrets follow:

```text
AWS Secrets Manager
        |
        v
External Secrets Operator
        |
        v
Kubernetes Secret
        |
        v
Application Pod
```

Secrets are not stored in Git or container images.

## Admission and Network Security

Kyverno runs in enforce mode and is used to validate workload requirements.

Controls include:

- signed AS Bank images
- non-root execution
- read-only root filesystems
- resource requests and limits
- required workload labels
- no privileged containers
- no host namespaces
- no `hostPath`
- no `latest` image tags

Pod Security Admission provides a second enforcement layer.

Application namespaces also use default-deny NetworkPolicies with explicit traffic allowances.

During Stage 6 verification, unsigned images, root containers, arbitrary HTTPS egress, and cross-namespace traffic were deliberately tested and rejected. :contentReference[oaicite:1]{index=1}

## Data Layer

Layer 3 manages separate PostgreSQL 16 databases for:

```text
customer-service
account-service
transaction-service
```

The RDS lifecycle supports:

```text
create
  |
  v
run
  |
  v
final snapshot
  |
  v
destroy
  |
  v
restore from latest complete snapshot
```

Snapshot restore and retention behaviour have been tested in dev. :contentReference[oaicite:2]{index=2}

## Authentication Infrastructure

Persistent Cognito infrastructure includes:

- one user pool
- dev, QA, and prod public frontend clients
- `CUSTOMER`, `OPERATIONS`, and `ADMIN` groups
- OAuth2 resource-server scopes
- synthetic demo users

The frontend uses public clients because browser applications cannot safely hold a client secret.

The final Authorization Code + PKCE browser flow is part of the remaining Stage 7 application work.

## Infrastructure CI

Terraform changes are validated through GitHub Actions.

The pipeline covers:

```text
terraform fmt
      |
      v
terraform validate
      |
      v
    tflint
      |
      v
   Checkov
      |
      v
terraform plan
      |
      v
human review
```

Persistent infrastructure applies after merge.

Cluster and data layers use explicit environment lifecycle workflows because those resources are intentionally ephemeral.

## Repository Structure

```text
.
├── .github/
│   └── workflows/
│
├── .githooks/
│
├── docs/
│   ├── adr/
│   ├── AS_BANK_PROJECT.md
│   └── SESSION-LOG.md
│
├── scripts/
│
├── terraform/
│   ├── bootstrap/
│   ├── network/
│   ├── cluster/
│   └── modules/
│
├── Makefile
└── README.md
```

`docs/AS_BANK_PROJECT.md` is the canonical project specification.

Architecture decisions are recorded under `docs/adr/`.

`docs/SESSION-LOG.md` records implementation continuity and unresolved work between sessions.

## Current Status

The project is currently in **Stage 7 — Full application**.

Completed infrastructure work includes:

- AWS account bootstrap and MFA-backed access
- Terraform remote state
- GitHub OIDC
- ECR
- Route 53
- dev and prod networking
- EKS
- Karpenter
- GitOps bootstrap with Argo CD
- External Secrets
- EKS Pod Identity
- Kyverno admission enforcement
- Pod Security Admission
- NetworkPolicy enforcement
- RDS lifecycle and snapshot restore
- Cognito
- full dev application workload deployment

The current Stage 7 work is completing:

- application release to GitOps promotion
- shared ALB ingress
- ExternalDNS
- CloudFront and remaining edge configuration
- real Cognito Authorization Code + PKCE login
- end-to-end authenticated transfer

Keeping this section explicit prevents planned architecture from being presented as completed work.

## Cost Discipline

The project has a gross AWS cost target below **$30 per month**.

Billable dev and prod infrastructure is destroyed when it is not required.

Persistent resources are limited to things that must survive environment teardown, such as Terraform state, ECR, DNS, IAM/OIDC, Cognito, and recovery data.

AWS Budgets and Cost Explorer are used to track spend independently of promotional credits.

## Non-Functional Targets

The platform is built against explicit engineering targets:

| Requirement | Target |
| --- | --- |
| Availability | 99.5% while active |
| Recovery Time Objective | 60 minutes or less |
| Recovery Point Objective | 5 minutes or less |
| Normal load | 20 requests/second |
| Peak load | 100 requests/second |
| Transfer throughput | At least 20 transactions/second |
| Transfer latency | p95 below 500 ms |
| Read latency | p95 below 300 ms |
| Gross AWS spend | Below $30/month |

These are learning-project targets used to drive engineering decisions and testing. They are not claims about real banking workloads. :contentReference[oaicite:3]{index=3}

## Related Repositories

### Application

[`as-bank-app`](https://github.com/sai-pillalamarri/as-bank-app)

Java 21 / Spring Boot services and React frontend, including application CI, security tests, container builds, SBOM generation, vulnerability scanning, and image signing.

### GitOps

[`as-bank-gitops`](https://github.com/sai-pillalamarri/as-bank-gitops)

Argo CD desired state for platform components and application workloads, including Helm configuration, security policies, NetworkPolicies, and environment-specific values.

## Project Scope

AS Bank is deliberately built with synthetic data.

It does not store real customer information, payment card data, production credentials, or regulated financial data.

The project exists to practise and demonstrate the engineering mechanisms behind cloud infrastructure, Kubernetes, delivery automation, security controls, reliability, recovery, and cost management.
