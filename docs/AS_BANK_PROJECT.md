# AS Bank — Project Document

Canonical specification for the AS Bank platform engineering project. This is the single source of truth for scope, architecture, standards, stages, and continuity.

**Never commit** real credentials, secrets, AWS account IDs, tokens, private keys, kubeconfigs, Terraform state, or real customer data.

---

## 1. Purpose

AS Bank is a banking platform built to develop **senior-level technical depth** across DevOps, DevSecOps, AWS, platform engineering, and SRE.

The banking domain is chosen because it justifies strict security, auditability, correctness, and availability requirements.

**The bar being aimed at:** given an unfamiliar system failing in an unfamiliar way, reason systematically to root cause without a tutorial.

**On completion, without notes, you can:**

- Debug a broken pod from symptom to root cause, explaining each step
- Explain the mechanism under every tool used, not only its configuration
- State what was rejected and why, for the decisions that mattered
- Describe what broke, what you did, and what changed afterwards

**Scope discipline:** this is a learning project using synthetic data. It must never be presented as production banking experience. Every README carries that statement.

---

## 2. Technology Stack

### Application

| Layer      | Technology                                                                                 |
| ---------- | ------------------------------------------------------------------------------------------ |
| Frontend   | React 19, TypeScript, Vite, React Router, shadcn/ui + Tailwind                             |
| Backend    | Java 21, Spring Boot 3.x, Spring Security (OAuth2 Resource Server), Spring Data JPA, Maven |
| Resilience | Resilience4j                                                                               |
| API docs   | springdoc OpenAPI                                                                          |
| Database   | PostgreSQL 16, Flyway, database-per-service                                                |

### Local development

Docker, Docker Compose, **kind**, Testcontainers, WSL2 on Windows 11.

### CI and supply chain

| Purpose                           | Tool                                        |
| --------------------------------- | ------------------------------------------- |
| CI                                | GitHub Actions (CI only, never CD)          |
| SAST + coverage                   | SonarCloud                                  |
| Dependency / image / IaC scanning | Trivy                                       |
| SBOM                              | Syft                                        |
| Image signing                     | Cosign / Sigstore (keyless via GitHub OIDC) |
| Secret scanning                   | Gitleaks + GitHub secret scanning           |
| Terraform policy                  | Checkov, tflint                             |
| DAST                              | OWASP ZAP baseline                          |
| Dependency updates                | Dependabot                                  |

### AWS

| Category | Services                                                              |
| -------- | --------------------------------------------------------------------- |
| Compute  | EKS, Karpenter, EC2 (Spot in dev, On-Demand in prod)                  |
| Registry | ECR                                                                   |
| Data     | RDS PostgreSQL                                                        |
| Network  | VPC, NAT Gateway, ALB, Route 53, ACM, CloudFront                      |
| Identity | IAM, STS, EKS Pod Identity, GitHub OIDC provider, AWS CLI `aws login` |
| Secrets  | AWS Secrets Manager                                                   |
| Auth     | Cognito                                                               |
| Cost     | AWS Budgets, Cost Explorer, cost allocation tags                      |

### Infrastructure as code

Terraform (layered state, reusable modules, S3 backend with native locking), Helm (with a shared library chart), Kustomize (environment overlays), Makefile (`make up` / `make down`).

### Kubernetes platform

Argo CD, Kyverno, External Secrets Operator, AWS Load Balancer Controller, ExternalDNS, EBS CSI driver, metrics-server, Pod Security Admission (restricted).

### Observability

Prometheus + Prometheus Operator, Grafana, Alertmanager, Loki, Tempo, OpenTelemetry, Micrometer + Spring Boot Actuator.

---

## 3. Architecture

### AWS account

One standalone AWS account, split by environment and lifecycle rather than by account boundary.

| Scope      | Contents                                                                                                                      | Lifecycle                                                                                               | Cost target                           |
| ---------- | ----------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ------------------------------------- |
| Persistent | Terraform state, ECR, GitHub OIDC provider and roles, Route 53 hosted zone, ACM certificates, Budgets                         | Never destroyed                                                                                         | Keep idle spend near $5/month or less |
| Dev / QA   | Dev VPC, EKS, Karpenter, RDS, ALB. `dev` and `qa` are **namespaces in one cluster**                                           | Cluster, data, NAT, ALB, and paid endpoints created only when needed                                    | ~$0.30/hour running                   |
| Prod       | Separate prod VPC plus the same modules with production values: multi-AZ where required, On-Demand nodes, RDS backups enabled | Cluster, data, NAT, ALB, and paid endpoints created only for promotion demos, blue-green, and DR drills | ~$0.45/hour running                   |

The account boundary is no longer the dev/prod security boundary. Isolation comes from separate VPCs, Terraform states, IAM roles, Kubernetes clusters, security groups, and naming/tagging. Prod still uses its own EKS cluster and RDS resources when it is stood up.

**Cost rules**

- AWS Budgets and email alerts configured **before** the first billable infrastructure deployment
- `make down` at the end of every AWS session; next session opens with a Cost Explorer check
- The account starts with $100 of promotional AWS credit. Track **gross cost before credits** so the project proves its own cost discipline
- Monthly gross AWS spend should stay below $30; the aim is to finish the AWS work inside the initial credit, not to depend on it
- Do not create AWS Organizations for this project. The single-account design does not need it
- Human access uses one named IAM operator user with MFA and no access keys. `aws login` provides temporary CLI credentials, then STS roles provide the working permissions
- The root user has MFA and is used only for account-level tasks that require root credentials

### Repositories

| Repo             | Contents                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------ |
| `as-bank-app`    | React frontend, three Spring Boot services, tests, Dockerfiles, Compose, CI workflows      |
| `as-bank-infra`  | Terraform: bootstrap, modules, per-layer environments, Terraform CI                        |
| `as-bank-gitops` | Argo CD desired state — `platform/` for cluster add-ons, `apps/` for application workloads |

The `platform/` and `apps/` split reflects different owners, change cadence, and blast radius.

### Services

| Service               | Responsibility                                 | Dependencies             |
| --------------------- | ---------------------------------------------- | ------------------------ |
| `customer-service`    | Customer profile and status                    | None (leaf)              |
| `account-service`     | Accounts, balances, types                      | Calls `customer-service` |
| `transaction-service` | Deposit, withdraw, transfer, history           | Calls `account-service`  |
| `frontend`            | React SPA served by nginx, deployed in-cluster | Calls all three          |

Communication is synchronous REST. Each service owns its own database schema and migrations.

`transaction-service` includes a **flag-gated failure injection endpoint** (latency, errors, memory pressure), disabled by default and documented as a chaos-testing affordance. This makes the SRE stages genuine rather than fabricated.

---

### DNS and certificates

**Domain:** `aslearnings.online`, registered at Hostinger.

**Delegation.** Create a Route 53 public hosted zone for `aslearnings.online` in the AWS account, then change the nameservers at Hostinger to the four Route 53 nameservers. Registration stays at Hostinger; all record management moves to Route 53, which is what ExternalDNS and ACM DNS validation require.

**Subdomain plan** — deliberately kept to a single label so one wildcard certificate covers everything.

| Environment | Frontend                                                    | API                          |
| ----------- | ----------------------------------------------------------- | ---------------------------- |
| dev         | `dev.aslearnings.online`                                    | `api-dev.aslearnings.online` |
| qa          | `qa.aslearnings.online`                                     | `api-qa.aslearnings.online`  |
| prod        | `aslearnings.online`, `www.aslearnings.online`              | `api.aslearnings.online`     |
| Auth        | `auth.aslearnings.online` (Cognito custom domain, optional) | —                            |

Use `api-dev.` rather than `api.dev.` — ACM wildcards match one label only, so two-level names would each need their own SAN.

**DNS access.** The hosted zone and both EKS environments live in the same AWS account. ExternalDNS uses a dedicated IAM role scoped to that hosted zone. Dev and prod use separate roles so a workload does not get broader DNS permissions just because the account is shared.

**Certificates**

- One ACM certificate covering `aslearnings.online` plus `*.aslearnings.online` serves every name above
- ACM certificates are regional: the ALB needs one in the cluster region, and **CloudFront requires one in `us-east-1`**. Same names, two certificates
- DNS validation via Route 53, so renewal is automatic
- ACM certificates are free; a hosted zone is $0.50/month

**ExternalDNS with ephemeral clusters**

- Set a unique `--txt-owner-id` per environment so rebuilt clusters do not fight over records
- Use `--policy=sync` so records are removed when the cluster is destroyed, leaving no orphaned entries pointing at deleted ALBs
- Records are recreated automatically on the next `make up`

**Certificates and the hosted zone are Layer 0** — never destroyed, so teardown never triggers revalidation.

---

## 4. Terraform Layering

Separate state files per layer and environment. This makes ephemeral clusters safe — a `destroy` of `dev/cluster` cannot touch `prod/cluster`, the network state, or bootstrap resources.

| Layer             | Contents                                                                            | Lifecycle                                  | Idle cost                                        |
| ----------------- | ----------------------------------------------------------------------------------- | ------------------------------------------ | ------------------------------------------------ |
| **0 — Bootstrap** | State bucket, ECR, GitHub OIDC roles, human IAM roles, Route 53                     | Never destroyed                            | Keep persistent idle spend near $5/month or less |
| **1 — Network**   | Separate dev and prod VPCs, subnets, route tables, gateway endpoints (S3, DynamoDB) | Kept; NAT destroyed                        | $0                                               |
| **2 — Cluster**   | Environment-specific EKS, Karpenter, node config, add-ons, **interface endpoints**  | Destroyed every session                    | $0                                               |
| **3 — Data**      | Environment-specific RDS                                                            | Snapshot before destroy, restore on create | Snapshot storage only                            |

Layer 0 has one state file. Layers 1–3 use separate `dev` and `prod` state keys. `qa` shares the dev infrastructure and differs only at the Kubernetes namespace and application configuration level. A prod destroy therefore targets prod state only; account-wide resource selection is never used.

**Interface endpoints are not free, and belong in Layer 2.** Gateway endpoints (S3, DynamoDB) cost nothing and stay in Layer 1 with the VPC, subnets, route tables, IGW, and security groups. Each PrivateLink interface endpoint — ECR API, ECR DKR, STS, Secrets Manager, CloudWatch Logs — bills roughly $0.01/hour per AZ, about $7/month each, plus data processing, whether or not anything is using it. Five of them left standing while the cluster is destroyed would cost more than the intended persistent idle baseline. They are only needed while the cluster runs, so they die with it.

The NAT Gateway (~$0.045/hour) is likewise destroyed with Layer 2 despite belonging logically to the network layer. This is the one place the layer boundary bends for cost reasons — record it in the layering ADR.

**Everything that must survive a teardown lives in Git or in persistent resources in the AWS account:**

- Argo CD config — bootstrapped from Git, never clicked in the UI
- Grafana dashboards — ConfigMaps in Git, never saved in the UI
- Prometheus rules and alerts — Git
- Images — ECR
- Secrets — AWS Secrets Manager, re-pulled by External Secrets on rebuild
- Seed data — Flyway migrations plus a seed script

**Target to measure and publish:** full platform rebuilds from zero to running application in under 30 minutes, from Git.

---

## 5. Local Workflow

An EKS cluster costs ~12 minutes to create and ~12 to destroy. Roughly 40% of Kubernetes work never needs AWS.

**Do on kind — free, instant, unlimited retries:**
Helm chart authoring, Kyverno policy development, NetworkPolicy design, Argo CD app-of-apps structure, Prometheus/Grafana/Loki/Tempo configuration, probes, HPA behaviour, PDB, rollout and rollback mechanics, most incident drills.

**Do on EKS — genuinely needs AWS:**
EKS Pod Identity, AWS Load Balancer Controller, Karpenter, External Secrets against Secrets Manager, RDS connectivity, IAM role boundaries, dev-to-prod promotion, DR drills, cost measurement.

---

## 6. Engineering Standards

**Branching — trunk-based development.** One long-lived branch: `main`. Protected and always deployable. Short-lived `feat/`, `fix/`, `chore/`, `docs/`, `ci/`, `refactor/` branches, merged via PR with required status checks. No direct pushes.

No `develop`, no `release/*`, no `hotfix/*`. Short-lived feature branches are part of trunk-based development, not a departure from it — what makes it trunk-based is that only one branch is long-lived.

GitFlow was considered and rejected. It suits versioned releases with long stabilisation periods; this project deploys continuously to dev and promotes an immutable digest to prod, so a release branch adds merge overhead without adding control. The control is the approval on the prod GitOps PR. Trigger to revisit: needing to support several released versions at once. Record as an ADR.

**Commits.** Conventional Commits, CI-enforced.

```
feat(account-service): add balance retrieval endpoint
fix(transaction-service): reject negative transfer amounts
ci: add cosign image signing to build workflow
```

**Pre-commit hooks.** gitleaks, terraform fmt, prettier, ESLint, spotless.

**ADRs.** `docs/adr/NNNN-title.md`, Nygard format, written at the moment of the decision. Each must contain at least **two rejected alternatives**, why they were rejected, what would make you revisit, and what this decision costs. Target 15–25.

### Writing standards

Everything committed to these repositories — code comments, READMEs, ADRs, runbooks, architecture notes, commit messages — must read as written by an engineer, not generated. This applies to anything drafted with AI assistance before it is committed.

**Code comments**

- Comment _why_, not _what_. `// retry only on 5xx — a 4xx means our request was wrong` is useful; `// retrieves the account` is noise
- No comment restating a method's name above every method
- No boilerplate Javadoc (`/** Constructs a new instance of X. */`)
- Sparse. A comment every few lines means most of them are wrong or will rot

**Documents**

- No filler: "it's important to note that", "in today's fast-paced environment", "let's dive in", "this comprehensive guide"
- No emoji headers, no decorative icons
- No Overview / Prerequisites / Conclusion scaffolding on a two-paragraph document
- State the awkward parts plainly. "Single-AZ NAT in dev because multi-AZ costs $65/month and I'm paying for this myself" reads human; "this design prioritises cost efficiency" does not
- Vary sentence length — uniform rhythm is the usual tell

**Commit messages.** Short and specific. Conventional Commits format, one line of substance, no paragraph explaining the philosophy of the change.

**ADRs, post-incident reviews, and the debug log are rewritten in your own words**, not committed as drafted. These are the documents you will be questioned on. Reasoning you did not construct yourself will not survive a follow-up question. AI drafts supply structure and technical substance; the judgement — particularly the "what would make me revisit this" section — is written by you.

**Not in scope:** deliberately inserted typos or manufactured informality. The target is documentation a competent engineer wrote quickly, not documentation pretending to be careless.

---

## 7. Backend Standards

### Structure

- Layered: controller → service → repository
- **DTOs at the boundary** — never expose JPA entities in a REST response
- Constructor injection only; no field `@Autowired`
- Package by feature (`customer/`, `account/`), not by layer

### API design

- **Versioned from day one** — `/api/v1/accounts`
- **RFC 7807 Problem Details** for errors; one consistent error shape across all services, with a correlation ID in every response
- **Idempotency keys on transfers** — store the key, return the original result on replay; a retry must not move money twice
- **Pagination on every collection endpoint**
- **OpenAPI generated** via springdoc, never hand-written

### Data correctness

- **Money is `BigDecimal`** with explicit scale, or minor units as `long`. Never `double`
- **Optimistic locking** (`@Version`) on account balances
- **Transaction boundaries explicit at the service layer**
- **Flyway migrations forward-only**, never edited after being applied
- **Append-only ledger** — corrections are reversing entries, not updates

### Resilience

- **Timeouts on every outbound call**, connect and read, explicitly set
- **Resilience4j** retry, circuit breaker, and bulkhead on service-to-service calls
- **Retry only idempotent operations**
- **Graceful shutdown** (`server.shutdown=graceful`) with a termination grace period matching the Kubernetes config
- **Correlation ID propagated** through every call and into every log line

### Testing

- **Testcontainers** against real PostgreSQL — not H2
- Unit tests on business logic: transfer rules, balance validation, idempotency
- `@WebMvcTest` for controller and security-layer behaviour
- Negative security tests (Section 8)
- Coverage 70–80% as a signal, not a target

### Container standards

- Multi-stage build, JRE runtime not JDK, pinned base image **digest** not tag
- Non-root user, read-only root filesystem
- Layered jars so dependency layers cache
- **`-XX:MaxRAMPercentage=75`**, not fixed `-Xmx`, so the heap tracks the cgroup limit

---

## 8. Application Security

### Principle

Each service is an **OAuth2 Resource Server**, not an authorization server. Cognito issues tokens; services only validate them. **No service has a login endpoint, a password store, or a token-signing key.**

```yaml
spring:
  security:
    oauth2:
      resourceserver:
        jwt:
          issuer-uri: https://cognito-idp.{region}.amazonaws.com/{userPoolId}
```

This provides JWKS discovery, key rotation, signature verification, issuer and expiry checks.

### Three Cognito-specific validations to add manually

- **`token_use` must equal `access`** — Cognito issues both ID and access tokens; accepting an ID token at an API is a vulnerability
- **`client_id`, not `aud`** — Cognito access tokens carry `client_id`; the standard audience validator will not catch this. Write a custom `OAuth2TokenValidator<Jwt>`
- **Scopes enforced explicitly** — a valid token is not an authorized one

### Role mapping

Cognito puts groups in `cognito:groups`; Spring expects `ROLE_`/`SCOPE_` authorities. A `JwtAuthenticationConverter` bridges them. Without it, `@PreAuthorize("hasRole('ADMIN')")` silently never matches.

Roles: `CUSTOMER`, `OPERATIONS`, `ADMIN`.

### Three authorization layers

1. **Filter chain** — coarse routing; health open, `/actuator/prometheus` restricted, everything else authenticated
2. **Method security** — `@PreAuthorize` role checks
3. **Ownership checks** — compare the token `sub` against the resource owner in the database

Layer 3 is the one that matters. A `CUSTOMER` with a valid token must not read another customer's account by changing the URL. This is Broken Object Level Authorization, number one on the OWASP API Security Top 10.

### Service-to-service

Client credentials flow plus an explicit user-context header, with the downstream service re-verifying ownership itself. Never trust a caller's claim about who the user is. NetworkPolicy underneath as defence in depth.

### Stateless configuration

`SessionCreationPolicy.STATELESS`. CSRF disabled **with a documented reason** (no cookies). CORS scoped to the real origin, never `*`.

### Local development

Spring profiles: `local` uses a mock issuer or Testcontainers Keycloak; `aws` uses the real Cognito issuer. **No profile that disables security.**

### Negative security tests — in CI

Assert rejection: expired token → 401; wrong issuer → 401; ID token instead of access token → 401; tampered signature → 401; valid token missing role → 403; valid token, another customer's account → 403.

---

## 9. Frontend Standards

**Target: clean and credible, not impressive.** Use the component library; do not hand-craft a design system. **Budget ~8 hours total** for anything beyond functional.

### Deployment

Deployed in-cluster as a fourth workload. Edge path: **CloudFront → ALB → Ingress → nginx pod.**

### Container hardening

- Multi-stage build: Node builds, runtime stage copies only `dist/`. Never ship `node_modules`
- **nginx-unprivileged** base, listening on 8080 (default nginx wants port 80 and root; Kyverno will reject it)
- Read-only root filesystem with `emptyDir` mounts for nginx temp paths
- SPA fallback: `try_files $uri $uri/ /index.html`
- Security headers at nginx **and** CloudFront

### Runtime configuration

Do **not** bake `VITE_API_URL` or the Cognito client ID into the bundle. Ship a `config.json` from a ConfigMap, fetched at app boot before render. The same image digest then promotes dev → qa → prod like every other service.

### Frontend auth

Authorization Code + PKCE. No implicit flow, no client secret in the browser. **Access token in memory only** — never `localStorage` or `sessionStorage`. Never decode the token to make authorization decisions.

### Two screens that demonstrate platform work

- **Environment / build info panel** — environment name, running image digest per service, service versions, backend health. Shows the promote-the-same-digest claim on screen
- **Operations page** — protected admin screen triggering the failure-injection endpoints, making incident drills recordable

---

## 10. Observability Standards

Instrumentation belongs in **Stage 1**, not Stage 8. Retrofitting produces worse metrics.

### Percentiles

```yaml
management:
  metrics:
    distribution:
      percentiles-histogram:
        http.server.requests: true
      slo:
        http.server.requests: 50ms,100ms,200ms,500ms,1s,2s
```

Use `percentiles-histogram`, **not** `percentiles`. Client-side percentiles cannot be aggregated across pods.

### Business metrics

- `asbank_transfers_total` — tagged by result: `success`, `insufficient_funds`, `account_frozen`
- `asbank_transfer_duration_seconds` — around the full transaction, not just the HTTP call
- `asbank_login_failures_total` — feeds a brute-force alert
- `asbank_downstream_calls_total` — tagged by target service and outcome

### Cardinality — hard rules

**Never tag with account number, customer ID, transaction ID, email, or raw amount.** Unbounded tags create unbounded time series, and metrics endpoints are less guarded than APIs, so PII in a label leaks into dashboards, alerts, and logs.

**Verify URI templating works** — if `/accounts/12345` is not normalised to `/accounts/{id}`, every account ID becomes a time series. Write a test for it.

### Actuator exposure

Separate management port (8081). `health/liveness` and `health/readiness` open to the kubelet. `/actuator/prometheus` reachable only from the monitoring namespace, enforced by NetworkPolicy. `env`, `heapdump`, `threaddump` **disabled**.

### Collection

`ServiceMonitor` per service, in the GitOps repo beside the Helm chart. Never hand-edited scrape config. Standard labels on every pod: `app`, `version`, `environment`, `team`, `cost-center`.

### SLOs

Transfer API availability 99.5%; transfer API p95 under 500ms. Published with error budgets. Alertmanager alerts on **error-budget burn rate**, not raw thresholds, via precomputed recording rules.

### Tracing

OpenTelemetry into Tempo. Enable **exemplars** so a latency spike in Grafana links directly to the causing trace.

### Ephemeral data

Prometheus history dies with the cluster. Accept this; use remote-write to Amazon Managed Prometheus or Grafana Cloud free tier only during the SRE and FinOps stages.

---

## 11. CI/CD Model

**GitHub Actions = CI. Argo CD = CD. No `kubectl apply` in a pipeline.**

### Application pipeline

```
PR:      lint → unit + integration (Testcontainers) → SonarCloud gate
         → Trivy fs → Gitleaks → negative security tests
         → blocked unless all pass

main:    build image (pinned base digest) → tag with git SHA
         → Trivy image scan → Syft SBOM attached → Cosign keyless sign
         → push to ECR (persistent registry in the same AWS account)

Stage 5 onward:
         → open PR against as-bank-gitops with the new digest
```

### Workflow layout and triggers

Workflows live in the repo whose code they build — a GitHub Actions workflow can only be triggered by events in its own repository.

| Repo             | Workflows                                                                                 |
| ---------------- | ----------------------------------------------------------------------------------------- |
| `as-bank-app`    | `ci.yml`, `release.yml`, plus reusable workflows                                          |
| `as-bank-infra`  | `terraform-plan.yml`, `terraform-apply.yml`, `environment-up.yml`, `environment-down.yml` |
| `as-bank-gitops` | Manifest validation only — Argo CD reads this repo, it is not a pipeline                  |

**Three triggers, three jobs**

| Trigger                    | Runs                                                     | Purpose                                                                                                              |
| -------------------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `push` to a feature branch | Tests, Sonar, Trivy fs, Gitleaks, ZAP baseline           | Fast feedback while working. Nothing published                                                                       |
| `pull_request` to `main`   | The same suite, registered as **required status checks** | Enforcement — merge is blocked until they pass                                                                       |
| `push` to `main`           | Build, scan, SBOM, sign, push to ECR                     | Produce and publish the artefact. The only trigger that touches AWS; from Stage 5 onward it also opens the GitOps PR |

Fast feedback and enforcement are different jobs. The push run gives speed; the PR run gives the guarantee. Keep both.

Split `ci.yml` (triggers 1 and 2) from `release.yml` (trigger 3) so the AWS-touching job cannot run on a feature branch.

**Path filters are mandatory.** Without them a README edit rebuilds four images:

```yaml
on:
  push:
    paths:
      - "customer-service/**"
```

**Reusable workflows, not copy-paste.** The three Java services have near-identical CI. Write it once as a `workflow_call` workflow and call it per service:

```yaml
jobs:
  build:
    uses: ./.github/workflows/reusable-java-ci.yml
    with:
      service: customer-service
```

Duplicated pipeline logic drifts. One service ends up on a different scanner version or a weaker gate, and nobody notices until it matters. The same argument as the shared Helm library chart.

Pin third-party actions to a commit SHA, not a tag — a tag can be moved, and a moved tag in a build pipeline is a supply-chain compromise.

### CI → GitOps handoff

From Stage 5 onward, after the GitOps application structure exists, **CI opens a pull request. It never pushes directly.**

- **Dev** — auto-merged once checks pass; Argo CD auto-syncs
- **Prod** — human approval required; Argo CD Application `automated: false`

### Infrastructure pipeline

**All Terraform runs in CI via environment-specific OIDC-assumed roles. Nothing applies from a workstation.** Dev and prod roles are separate even though they live in the same AWS account. Only the trigger differs by layer.

**Every layer, on every PR:**

```
terraform fmt -check → validate → tflint → Checkov (blocking on high)
  → terraform plan posted as a PR comment → human review
```

**Apply trigger by layer**

| Layer         | Trigger                                                                 | Reason                                              |
| ------------- | ----------------------------------------------------------------------- | --------------------------------------------------- |
| 0 — Bootstrap | Merge to `main`                                                         | Account-wide persistent resources, changed in place |
| 1 — Network   | Merge to `main`                                                         | Persistent dev/prod VPC state, changed in place     |
| 2 — Cluster   | Manual `workflow_dispatch` with `environment=dev` or `environment=prod` | Created and destroyed on demand                     |
| 3 — Data      | Manual `workflow_dispatch` with `environment=dev` or `environment=prod` | Created and destroyed on demand                     |

`make up` and `make down` are thin wrappers that trigger the workflow rather than running Terraform locally. Dev is the default; prod must be named explicitly:

```makefile
ENV ?= dev

up:
	gh workflow run environment-up.yml -f environment=$(ENV)

down:
	gh workflow run environment-down.yml -f environment=$(ENV)
```

`make up ENV=prod` and `make down ENV=prod` use prod-specific Terraform state and IAM roles. There is no command that destroys both environments at once.

**Why not apply ephemeral layers locally:** the pipeline gives an audit trail of who applied what and when, keeps AWS credentials off the workstation, and pins the Terraform and provider versions so local drift cannot cause a difference between environments. Running Terraform locally stays available for debugging — `state show`, targeted plans — but is not the routine path.

Record the per-layer trigger model as an ADR.

### DAST

DAST needs a running target, which an ephemeral cluster does not always provide. Two levels, run in different places.

**Baseline scan — Stage 3, in CI, on every PR.** Bring the app up with Docker Compose inside the GitHub Actions runner, run the ZAP baseline scan against `localhost`, tear it down. No AWS, no cost, no external target registration. Catches missing security headers, cookie flags, information disclosure, and obvious injection surfaces. Fails the build on high severity; warns on medium.

**Authenticated scan — Stage 7, against the live dev environment, run manually.** An unauthenticated scan of a banking API returns 401 everywhere and finds nothing meaningful. Configure ZAP with a valid Cognito access token so it can probe behind the login:

- Whether a `CUSTOMER` token reaches `ADMIN` endpoints
- Whether changing an account ID in a URL returns another customer's data — the Broken Object Level Authorization control from Section 8

Import the springdoc OpenAPI spec rather than relying on the crawler. Exclude logout and destructive endpoints from active scanning.

**Practices to exercise, not just the scan**

- Scope definition — what is in, out, and never touched by an active scan
- Passive versus active scanning, and why active never runs against production
- Build gating thresholds — fail on everything and the scan gets disabled within a week
- False-positive triage with a documented justification that survives the next scan
- The remediation loop: finding → triage → fix → rescan → verify closed

**Evidence to produce:** deliberately weaken one control (remove a security header, or bypass an ownership check), let the scan catch it, fix it, and record before/after. Also write up one genuine false positive and its suppression rationale.

**Tooling note.** Enterprise platforms such as Veracode or Checkmarx are what UK banks typically run, mainly for policy governance and compliance reporting rather than better detection. They are priced per application portfolio and require agents to reach targets behind a firewall — neither fits an ephemeral personal environment. ZAP exercises the same principles. Record the choice in an ADR.

### Promotion

Build once. Promote the **image digest** — never a rebuild, never a floating tag. The same `sha256:` appears in dev, qa, and prod.

---

## 12. Platform and Security Standards

### Ingress

**AWS Load Balancer Controller with Ingress resources.** No in-cluster ingress proxy to run, scale, or patch; native ACM, WAF, and access-log integration.

**One shared ALB.** Every Ingress carries `alb.ingress.kubernetes.io/group.name: as-bank` with an explicit `group.order`. Without an IngressGroup each Ingress provisions its own ALB at ~$16–23/month.

**Target mode `ip`**, not `instance` — the ALB routes directly to pod IPs rather than via NodePort and kube-proxy, and sees real pod health.

**Pod readiness gates enabled** by labelling each application namespace `elbv2.k8s.aws/pod-readiness-gate-inject: enabled`. Without this, `ip` mode drops requests during rolling updates because pods report Ready before ALB target registration completes. Combined with `preStop` hooks and graceful shutdown, this gives genuine zero-downtime rollouts.

**ALB locked to CloudFront** — security group referencing the `com.amazonaws.global.cloudfront.origin-facing` managed prefix list, plus a secret custom header injected by CloudFront and verified by a listener rule. Without both, the ALB is reachable directly and CloudFront can be bypassed.

**TLS** terminates at the ALB using the ACM certificate; HTTP listeners redirect to HTTPS via `alb.ingress.kubernetes.io/ssl-redirect`.

**Gateway API** is the successor to Ingress, which is feature-frozen. Build on Ingress; record the trade-off in an ADR and treat Gateway API as an optional Stage 13 extension.

### Every workload ships with

Resource requests and limits; liveness, readiness, and startup probes; `runAsNonRoot` and read-only root filesystem with dropped capabilities; PodDisruptionBudget; HorizontalPodAutoscaler; topology spread constraints; default-deny NetworkPolicy plus explicit allows; a dedicated ServiceAccount bound to a least-privilege IAM role.

**Karpenter** provisions nodes — Spot in dev, On-Demand in prod.

Helm charts use a shared library chart. Environment differences live in `values-*.yaml`, never in separate charts.

### Secret delivery chain

```
AWS Secrets Manager → External Secrets Operator (via EKS Pod Identity)
  → Kubernetes Secret → mounted into pod
```

No secret in Git, in a Helm value, or in an image.

### Identity chain

```
GitHub Actions → OIDC → env IAM role      (no static keys; dev/prod separated)
Pod            → EKS Pod Identity → role  (no node-level permissions)
Human          → IAM user + MFA → `aws login` → STS role  (temporary credentials, no access keys)
```

### Supply chain — five steps

1. Build from a pinned base digest
2. Trivy scan — critical CVEs block
3. Syft SBOM, attached as an OCI artefact
4. Cosign keyless signature via GitHub OIDC identity
5. **Kyverno verifies the signature at admission** — an unsigned image cannot run

### Kyverno policies — `enforce` mode

Signed images from the ECR registry only; no `latest` tags; `runAsNonRoot`; read-only root filesystem; dropped capabilities; requests and limits mandatory; no privileged containers, host namespaces, or hostPath; required cost-allocation labels. Pod Security Admission at `restricted` as a second layer.

---

## 13. Out of Scope

Not built. Each gets an ADR stating the use case, why it is excluded, and the trigger that would change the answer.

| Excluded                                              | Trigger that would change it                                                                                                                                          |
| ----------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Kafka / MSK                                           | Audit must be non-blocking; a consumer needs offset replay; a third team needs the events                                                                             |
| SNS / SQS                                             | Optional post-project addition (~4 hours) if async messaging is wanted                                                                                                |
| Service mesh                                          | Many teams needing consistent policy without touching application code                                                                                                |
| Multi-region                                          | An RTO a single region cannot meet                                                                                                                                    |
| Event sourcing / CQRS                                 | Read and write models genuinely diverging in shape or scale                                                                                                           |
| GraphQL                                               | Client query patterns REST cannot serve efficiently                                                                                                                   |
| Argo Rollouts / Flagger                               | Release volume high enough that manual promotion is the bottleneck                                                                                                    |
| AWS Organizations / multi-account IAM Identity Center | Account-level prod isolation, SCPs, or centralized multi-account workforce access becomes a requirement and promotional-credit preservation is no longer a constraint |

**Principle:** every component costs build time, operational surface, teardown complexity, and an obligation to explain it under questioning. A project with five well-understood components beats one with twelve you can half-explain.

---

## 14. Stages

**No fixed calendar.** A stage is done when its exit criteria are met. Hour estimates are planning guides, not targets.

**Time split within any session:** roughly 70% project work, 20% fundamentals (Section 15), 10% drills and write-up (Section 16).

### Core stages

| Stage                       | Effort | Exit criteria                                                                                                                                                                                                                                                                                                 |
| --------------------------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **0 — Foundations**         | 6–8h   | NFR document; three repos; branch protection; pre-commit hooks; ADR process; ADR 0001 (repo split) and 0002 (single-account strategy)                                                                                                                                                                         |
| **1 — Walking skeleton**    | 8–10h  | `customer-service` running locally: one endpoint, Flyway, Spring Security resource server against a mock issuer, Actuator with histogram buckets and one business metric; React shell calling it                                                                                                              |
| **2 — AWS foundation**      | 16–20h | One standalone AWS account; MFA-protected human access via `aws login` and STS roles; GitHub OIDC roles; Terraform Layer 0 including ECR; budgets alerting on a test threshold; zero static access keys anywhere                                                                                              |
| **3 — CI and supply chain** | 16–20h | Application CI gate complete; signed image with attached SBOM pushed to ECR through OIDC, verifiable with `cosign verify`; a PR visibly failing on an injected CVE; negative security tests in the gate                                                                                                       |
| **4 — Network and cluster** | 28–35h | Layers 1–2 in Terraform with separate dev/prod state; Karpenter; Terraform CI with plan-on-PR; `make up` / `make down` working; Cost Explorer confirms no residual ephemeral spend after teardown                                                                                                             |
| **5 — GitOps**              | 16–20h | Argo CD; app-of-apps; `platform/` and `apps/` split; a merged PR produces a running pod with no human `kubectl`                                                                                                                                                                                               |
| **6 — Hardening**           | 16–20h | External Secrets; Pod Identity; Kyverno in enforce mode; signature verification; NetworkPolicies; RBAC; PSA. Screenshot the cluster rejecting an unsigned image and a root container                                                                                                                          |
| **7 — Full application**    | 35–40h | Three services; frontend in-cluster; RDS; real Cognito (issuer swap only); 5–10 demo Cognito users provisioned through Terraform with matching customer and account seed data through Flyway; Route 53, ACM, CloudFront; a real login and transfer end to end. Customer self-registration is not implemented. |
| **8 — Observability**       | 16–20h | Prometheus, Grafana, Loki, Tempo, OpenTelemetry; one trace spanning all three services; SLO dashboard with burn-rate alerts                                                                                                                                                                                   |

**Why AWS foundation comes before CI.** Cosign stores a signature as an OCI artefact beside the image, so the signing step needs a registry to be verifiable at all. Building the application pipeline before ECR exists would mean publishing somewhere temporary and repointing later. Real teams never hit this — the platform foundation exists long before anyone writes an application pipeline. Stage 2 creates the account, identity, Terraform Layer 0 and ECR; Stage 3 then builds a pipeline that has somewhere to publish.

**Bootstrap exception.** Terraform Layer 0 cannot initially use an S3 backend that does not exist yet, and CI cannot assume IAM roles that Layer 0 has not created yet. Apply the minimal bootstrap once from the workstation using the MFA-protected operator session and local state. After the state bucket exists, migrate the state into the S3 backend with `terraform init -migrate-state`. Commit only the Terraform and backend configuration. Never commit `.tfstate` files. Every routine apply after bootstrap runs through CI. Document this as the single manual apply in the project.

### Checkpoint — after Stage 8

| Effort | Exit criteria                                                                 |
| ------ | ----------------------------------------------------------------------------- |
| 8–10h  | READMEs; C4 diagrams; ADR index; demo recording; Well-Architected self-review |

**This is the milestone that matters.** At this point the project is portfolio-presentable and goes into job applications. Everything beyond is upside, not prerequisite. Do not skip it to press on.

### Differentiator stages

| Stage                       | Effort | Exit criteria                                                                                                                                                         |
| --------------------------- | ------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **9 — Release engineering** | 16–20h | dev → qa → prod digest promotion; manual prod gate; blue-green; a deliberate bad release and timed rollback                                                           |
| **10 — SRE and incidents**  | 16–20h | Eight scenarios injected and diagnosed; a runbook each; three full post-incident reviews with timelines and actions                                                   |
| **11 — Disaster recovery**  | 16–20h | RDS point-in-time restore; full cluster rebuild from Terraform; GitOps recovery; measured RTO and RPO                                                                 |
| **12 — FinOps**             | 16–20h | Karpenter consolidation; Spot; right-sizing from real Prometheus data; cost tags; teardown automation; `docs/COST-REPORT.md` with real spend and before/after numbers |
| **13 — Packaging**          | 16–20h | Final diagrams; ADR index; badges; demo video; interview talking points; public-release security review; repos public and pinned                                      |

**Total: roughly 250–300 hours.**

### Pacing notes

- **Stage 4 is where projects stall.** Terraform plus EKS plus IAM is the hardest combination here. Budget generously; overrun is not failure
- **Learning time is not typing time.** Generated config is fast; understanding why yours fails is not
- **Finish a stage before starting the next.** Half-finished stages accumulate into a project you cannot demo
- **If you cannot explain a stage, it is not finished** regardless of what is running
- **Apply for roles while building.** The project supplements the job search; it does not gate it

---

## 15. Fundamentals Track

Roughly 20% of working time, separate from project work. This builds debugging ability, which is what "senior" is tested on.

**Tier 1 — foundations**
Linux internals (cgroups and namespaces — containers _are_ these; process states, signals, file descriptors, memory accounting). Networking (DNS resolution path, TCP handshake and states, TLS handshake, routing, MTU, connection vs read timeouts).

**Tier 2 — daily surface, at depth**
Kubernetes mechanics (scheduler decisions, QoS classes and eviction order, OOMKilled vs evicted, probe semantics and their effect on traffic, rolling update surge/unavailable, the Service → Endpoints → kube-proxy → pod path, the admission chain). IAM policy evaluation (explicit deny, permission boundaries, identity vs resource policies, trust policies, evaluation order). VPC networking (route tables, NAT semantics, security groups vs NACLs, VPC endpoints, in-VPC DNS).

**Tier 3 — operational craft**
Terraform beyond apply (state internals, dependency graph, `moved` blocks, `import`, drift, recovering from a half-applied run). Debugging methodology. Bash and Python that are idempotent and fail safely.

**Tier 4 — deepen opportunistically**
CI/CD pipelines, container builds, Helm, Git internals.

### Self-diagnostic — hesitation marks the gap

1. A pod is OOMKilled at a 512Mi limit with a 400Mi JVM heap. Why?
2. A readiness probe fails on one of three replicas. What happens to in-flight requests? To new ones?
3. A pod reaches one service but not another. Walk the resolution path.
4. An IAM role has an allow but the call is denied. List every possible reason.
5. `terraform apply` fails halfway. What is the state of the world, and what do you do?
6. p99 latency triples, p50 is flat. What does that pattern tell you?

---

## 16. Break/Fix Drills

Ten to twenty minutes each. Run on kind where possible.

| Drill                                   | What it teaches                                      |
| --------------------------------------- | ---------------------------------------------------- |
| Memory limit below JVM heap             | OOMKilled mechanics, JVM ergonomics vs cgroup limits |
| Delete a NAT route                      | VPC routing, egress failure signatures               |
| Overly-strict NetworkPolicy             | Policy evaluation, DNS dependency, packet path       |
| Permission boundary blocking a pod role | IAM evaluation order                                 |
| Readiness probe pointed at a dead path  | Endpoint removal, traffic shifting                   |
| Liveness probe with too short a timeout | Restart loops caused by monitoring, not the app      |
| Corrupt Terraform state                 | State internals, recovery procedure                  |
| Unsigned image                          | Kyverno admission, supply-chain enforcement          |
| Downstream service returning 500s       | Cascading failure, timeout and retry behaviour       |
| Node deleted under a running workload   | Rescheduling, PDB, topology spread                   |

**Method:** when something breaks, spend 20 minutes reasoning before asking. Write the hypothesis down before testing it.

**Keep `docs/DEBUG-LOG.md`:** symptom → hypotheses → what you tested → what it actually was.

---

## 17. Deliverables

**Three public repositories** — `as-bank-app`, `as-bank-infra`, `as-bank-gitops`.

**Seven documents**

- NFR document — the requirements everything was derived from
- 15–25 ADRs with rejected alternatives
- `docs/DEBUG-LOG.md` — accumulated troubleshooting, reasoned in writing
- Three post-incident reviews with timelines and actions
- DR report with measured RTO and RPO
- `docs/COST-REPORT.md` with real spend and before/after optimisation numbers
- Threat model and Well-Architected self-review

**Demonstrable proofs**

- The same image digest running in dev and prod, side by side
- The cluster rejecting an unsigned image and a root container
- One trace spanning all three services
- Full platform rebuilt from zero in under 30 minutes
- A 2–3 minute demo recording

---

## 18. Continuity

The **repository is the real source of truth** — not this document, not chat history, not any AI memory. Git log, commits, ADRs, and the session log survive everything.

### Working style

- Mechanism over recommendation — every step explained by how the underlying thing works
- Application code may be generated in batches; platform, Terraform, and security work is incremental and understood before moving on
- One step at a time; no full-stage code dumps
- Command output requested where verification matters

### How explanations are written

Plain language. Short sentences. One idea at a time.

- Say it the way you would to a colleague at a whiteboard, not the way a textbook would
- Define a term the first time it appears, in a few words, then use it normally
- Use a concrete example or a number instead of an abstract description where one exists
- No long sentences with three clauses stacked together
- No academic phrasing when a direct sentence does the job
- Depth stays senior-level — this is about how it is said, not how much is left out
- If an explanation runs past a few paragraphs for a small decision, it is too long. Give the decision and one line of why, and offer the detail if wanted

Being hard to follow is a failure of the explanation, not a sign of rigour.

### Session log

Maintain `docs/SESSION-LOG.md` in `as-bank-infra`. One block per session:

```
## Session 12 — 2026-09-04
Stage: 4 (Network and cluster)
Done: VPC module, private/public subnets, single-AZ NAT
In progress: EKS module — cluster creates, nodes not joining
Blocked on: node group IAM role missing AmazonEKSWorkerNodePolicy (suspected)
Next: fix node role, then Karpenter
Branch: feat/eks-module
Decisions: single-AZ NAT in dev (ADR 0007)
```

### End-of-session ritual

1. Commit and push all work
2. Update Section 19 of this document
3. Add the session log entry, including any unresolved hypothesis
4. Tear down resources and confirm teardown. Use `make down` once the environment workflow exists; before then, stop local processes and run `docker compose down` where applicable

---

## 19. Current Status

**Stage:** 7 — Full application not started

**Completed**

21. New AWS account access verified
22. Root account protected with MFA
23. `as-bank-operator` IAM user created with MFA and no static access keys
24. Temporary CLI authentication verified through `aws login`
25. `us-east-1` selected as the primary workload region
26. ADR 0003 — trunk-based development
27. Terraform Layer 0 bootstrap started using the documented local-state bootstrap exception
28. $30/month AWS Budget created through Terraform with promotional credits excluded
29. Budget notification configuration verified at $0.01 actual spend, 80% actual spend, and 100% actual spend
30. Initial AWS inventory verified before bootstrap
31. Terraform Layer 0 applied and verified with no unexpected destroys
32. Persistent S3 state bucket created with versioning, encryption, public-access blocking, and native state locking
33. Four persistent ECR repositories created with immutable tags and scan-on-push
34. Route 53 hosted zone created and Hostinger delegation verified through Google and Cloudflare DNS
35. GitHub OIDC provider plus application-release, infrastructure-plan, and infrastructure-apply roles created
36. MFA-protected human STS operator role created and verified with a fresh role session
37. Direct AdministratorAccess removed from the login user and moved behind the operator role
38. Old static AWS CLI credentials removed; the project operator has zero IAM access keys
39. Bootstrap state migrated from local state to the S3 backend with `terraform init -migrate-state`
40. Remote state verified with a zero-drift Terraform plan
41. Stage 3 application CI gate completed with path-aware backend and frontend jobs
42. Customer-service negative JWT security integration tests added and enforced by CI
43. Separate SonarQube Cloud projects and quality gates configured for customer-service and frontend
44. Trivy filesystem scanning, Gitleaks, and ZAP baseline scanning enforced by the PR gate
45. Dependabot vulnerability alerts, automated security fixes, and weekly dependency updates enabled
46. Strict branch protection requires the PR gate against the latest main
47. Pinned multi-stage customer-service and frontend container images implemented
48. Main-only release workflow verified through GitHub OIDC and the application-release IAM role
49. Trivy image scanning and Syft SPDX SBOM generation verified
50. Customer-service and frontend images pushed to ECR by immutable Git SHA and digest
51. Cosign keyless image signing and signed SPDX SBOM attestations verified
52. `cosign verify` succeeded for both released images
53. Injected-CVE PR proof completed: Trivy and the required PR gate rejected Log4j 2.14.1
54. Negative-security-test proof completed: removing `token_use` validation failed `SecurityIntegrationTest` and the required PR gate
55. Stage 3 — CI and supply chain exit criteria completed
56. Terraform Layer 1 implemented with separate persistent dev and prod network roots and state
57. Terraform Layer 2 implemented with separate ephemeral dev and prod cluster roots and state
58. Dev and prod VPCs, public/private subnets, route tables, Internet Gateways, and S3/DynamoDB gateway endpoints implemented
59. Dev uses one NAT Gateway while prod uses one NAT Gateway per AZ
60. EKS, bootstrap managed node groups, NAT gateways, paid interface endpoints, Pod Identity, and Karpenter implemented in Layer 2
61. EKS access configured for the operator, infrastructure-plan, and infrastructure-apply roles
62. Karpenter 1.14.1 installed through Terraform-managed Helm
63. Dev Karpenter capacity configured for Spot and prod for On-Demand
64. AWS Free account plan compatible node types configured: `c7i-flex.large` for bootstrap and `c7i-flex.large` / `m7i-flex.large` for Karpenter
65. Terraform PR CI verified with static checks plus separate bootstrap, network-dev, network-prod, cluster-dev, and cluster-prod plans
66. Persistent Terraform apply verified through GitHub OIDC with bootstrap applied before the network roots
67. `make up ENV=dev` verified against a healthy EKS cluster and bootstrap node
68. Karpenter functional proof completed: a constrained pod triggered a new `c7i-flex.large` Spot node, the NodeClaim became Ready, and AWS reported `InstanceLifecycle=spot`
69. Karpenter destroy ordering fixed so its generated AWS resources are cleaned before the cluster IAM and EKS resources disappear
70. `make down ENV=dev` verified with the live Karpenter proof workload still present
71. Final teardown completed without manual IAM cleanup
72. Post-teardown checks confirmed no dev EKS cluster, NAT gateway, paid interface endpoints, EC2 nodes, or generated Karpenter instance profile remained
73. Cost Explorer showed no positive Stage 4 service cost immediately after teardown; the result was still marked estimated
74. Stage 4 — Network and cluster exit criteria completed
75. Argo CD bootstrapped through Terraform Layer 2 with an environment-specific root Application
76. GitOps app-of-apps structure implemented with separate `bootstrap/`, `platform/`, and `apps/` trees for dev and prod
77. GitOps manifest validation added and enforced as a required check on `as-bank-gitops` main
78. Terraform environment creation updated so Argo CD and Karpenter install in the second apply after the EKS API becomes reachable
79. Terraform PR planning and environment teardown updated to include the Argo CD runtime
80. Terraform PR gate passed static checks plus bootstrap, network-dev, network-prod, cluster-dev, and cluster-prod plans
81. Dev Argo CD root, platform, and application Applications reached `Synced` and `Healthy`
82. Initial GitOps proof workload reconciled to a running `version=stage5` pod without `kubectl apply`
83. A merged GitOps PR advanced `apps-dev` from Git revision `9376955` to `0914fc9` and rolled the workload to `version=stage5-pr-proof` without manual sync
84. `make down ENV=dev` destroyed the Stage 5 environment successfully in 6m31s
85. Post-teardown checks confirmed no dev EKS cluster, NAT Gateway, paid interface endpoints, or running EC2 instances remained
86. Stage 5 — GitOps exit criteria completed
87. External Secrets Operator added as Terraform-managed Layer 2 runtime infrastructure
88. External Secrets integrated with AWS Secrets Manager through EKS Pod Identity using environment-scoped IAM permissions
89. External Secrets end-to-end proof completed: a synthetic Secrets Manager value synchronized into a Kubernetes Secret unchanged
90. Kyverno installed through Terraform with enforce-mode workload and image validation policies managed through GitOps
91. Kyverno admission controller integrated with private ECR through EKS Pod Identity and scoped ECR read permissions
92. Signed-image admission proof completed: the Stage 3 signed customer-service digest was accepted
93. Unsigned-image rejection proof completed: the same image copied without its Cosign signature was rejected by Kyverno
94. Pod Security Admission configured at `restricted:v1.35` for dev and prod application namespaces
95. Root-container rejection proof completed: `runAsNonRoot=false` and `runAsUser=0` were rejected by Pod Security Admission
96. Application namespace ServiceAccounts configured with `automountServiceAccountToken: false`
97. RBAC proof confirmed the default dev ServiceAccount cannot read Secrets or create Pods
98. VPC CNI NetworkPolicy enforcement enabled and verified
99. Default-deny ingress and egress NetworkPolicies added with an explicit DNS egress allowance
100.  NetworkPolicy egress proof completed: Kubernetes DNS remained reachable while arbitrary HTTPS egress was blocked
101.  NetworkPolicy ingress proof completed: cross-namespace traffic to an `as-bank-dev` service was blocked
102.  Argo CD root, platform, and application Applications remained `Synced` and `Healthy` with Stage 6 controls active
103.  Temporary Stage 6 proof resources and the deliberately unsigned ECR image were removed after verification
104.  `make down ENV=dev` completed successfully after Stage 6 verification
105.  Post-teardown checks confirmed no dev EKS cluster, NAT Gateway, paid interface endpoints, dev EC2 instances, or dev cluster IAM roles remained
106.  Stage 6 — Hardening exit criteria completed

**Open decisions**

None.

**Next actions**

1. Begin Stage 7 — Full application
2. Implement account-service and transaction-service
3. Add RDS with database-per-service ownership and Flyway migrations
4. Replace the local OAuth2 issuer with real Cognito
5. Provision the demo Cognito users and matching synthetic customer/account data
6. Deploy all three services and the frontend through GitOps
7. Add Route 53, ACM, CloudFront, and the production edge path
8. Prove a real Cognito login and transfer end to end

## 20. Prompts

Three prompts cover the whole project lifecycle. Attach this document with each of them.

### Prompt 1 — Project kickoff (first chat only)

```
Attached is AS_BANK_PROJECT.md — the canonical specification for a
platform engineering project I'm building. Read it fully.

Treat it as settled. Do not redesign the architecture, change the
stack, or restructure the stages. If you think something in it is
wrong, say so once and then follow it unless I agree to change it.

I'm starting at Stage 0, nothing built yet.

Before we begin, confirm you have understood:
- The three-repo and single-account environment-isolation structure
- The stage sequence and their exit criteria
- The working style in Section 18 and writing standards in Section 6

Then start me on the first Stage 0 deliverable: the NFR document.
Work one step at a time and explain the mechanism behind each step,
not just the commands.
```

### Prompt 2 — Handoff (run at the end of every chat, before closing it)

```
We're ending this chat. Produce a handoff block for the next one.

Include only what's needed to continue — no discussion history,
no rationale we already settled, no summary of things you explained.

Format exactly:

## Session N — [date]
Stage: [number and name]
Done: [completed and verified this session]
In progress: [partially done, and exactly where it stopped]
Blocked on: [current problem plus my working hypothesis, if any]
Next: [the immediate next step]
Branch: [current branch]
Decisions: [new decisions made, with ADR number if written]
Files changed: [paths touched this session]
Gotchas: [anything that cost me time and would cost it again]

Then tell me what to update in Section 19 of AS_BANK_PROJECT.md
before I close this chat.
```

Paste the block into `docs/SESSION-LOG.md`, commit, and push.

### Prompt 3 — Session start (every chat after the first)

```
Attached is AS_BANK_PROJECT.md — the canonical specification for this
project. Read it fully and follow it. Do not redesign it.

Where I am:

[paste the latest block from docs/SESSION-LOG.md]

Live repo state:
[paste output of:]
  git branch --show-current
  git status -sb
  git log --oneline -8

The repo state above overrides the session log if they disagree.

Pick up from "Next" in the session log. Work one step at a time,
explain the mechanism behind each step rather than just the commands,
and ask for command output where verification matters. Don't dump a
whole stage of code at once.

Follow the writing standards in Section 6 for all generated code
comments, READMEs, ADRs, and documents — they must read as
human-written, not AI-generated.
```

### How they fit together

```
First chat        →  Prompt 1  →  work  →  Prompt 2  →  commit session log
Every later chat  →  Prompt 3  →  work  →  Prompt 2  →  commit session log
```

The document carries the _what_. The session log carries the _where_.
Git carries the truth — when any two disagree, the repository wins.
