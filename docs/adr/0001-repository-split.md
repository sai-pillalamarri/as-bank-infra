# ADR 0001: Split application, infrastructure, and GitOps state into separate repositories

## Status

Accepted

## Context

AS Bank contains three kinds of change with different purposes and risk.

Application code changes frequently and includes the React frontend, Spring Boot services, tests, Dockerfiles, and application CI.

Infrastructure code changes AWS resources through Terraform. These changes have a different review surface because a mistake can affect networking, IAM, EKS, RDS, or persistent infrastructure.

GitOps state represents what should be running in Kubernetes. Argo CD watches this repository and reconciles the cluster toward that state.

Keeping all three concerns in one repository would couple unrelated change histories and permissions. It would also make the CI-to-GitOps handoff less explicit.

## Decision

Use three repositories:

- `as-bank-app` for application code and application CI
- `as-bank-infra` for Terraform, infrastructure CI, ADRs, and platform-level project records
- `as-bank-gitops` for Argo CD desired state, Helm values, and Kubernetes environment configuration

Application CI may open a pull request against `as-bank-gitops` when a new image digest is ready for deployment. It does not deploy directly to Kubernetes.

Infrastructure changes remain independent from application release changes.

## Consequences

Application, infrastructure, and deployment state have separate histories and review boundaries.

The GitOps repository becomes a clear audit record of what version was intended to run in each environment.

Terraform changes cannot be mixed accidentally into normal application commits.

The cost is more repository administration. Branch protection, hooks, CI settings, permissions, and documentation conventions must be maintained in three places.

Cross-repository automation is also required when application CI updates an image digest in the GitOps repository.

## Rejected alternatives

### Single monorepo

Keep application code, Terraform, and GitOps state in one repository.

This would make initial setup simpler and reduce duplicated repository configuration.

It was rejected because application changes, infrastructure changes, and desired deployment state have different change cadence, permissions, and blast radius. A single history would also weaken the separation between CI producing an artifact and GitOps promoting that artifact.

### Two repositories: application and platform

Keep application code in one repository and combine Terraform with GitOps state in a second repository.

This would preserve some separation while reducing repository count.

It was rejected because Terraform describes infrastructure creation while GitOps describes Kubernetes desired state. They are applied by different mechanisms and have different failure modes. Combining them would make the ownership boundary between infrastructure provisioning and continuous reconciliation less clear.

## Revisit when

Reconsider this split if repository administration becomes a material burden for the project, or if the infrastructure and GitOps change lifecycle becomes tightly coupled enough that maintaining separate histories no longer provides useful isolation.
