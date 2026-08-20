# ADR 0002: Use one standalone AWS account

## Status

Accepted

## Context

AS Bank needs separate dev and prod environments while staying within the cost limits of a personal learning project.

The AWS account has promotional credit available. Creating an AWS Organization would add account-level isolation and centralized workforce access, but it is not required to exercise the main EKS, Terraform, IAM, GitOps, security, observability, and SRE goals of this project.

Using multiple AWS accounts would also introduce additional account administration and cross-account configuration.

The project still needs meaningful separation between dev and prod. A mistake in dev should not automatically target prod resources.

## Decision

Use one standalone AWS account.

Dev and prod remain separate through:

- separate VPCs
- separate EKS clusters when prod is running
- separate RDS resources
- separate Terraform state keys
- separate IAM roles
- separate security groups
- separate naming and cost-allocation tags
- environment-specific CI inputs and GitHub OIDC roles

QA runs as a namespace in the dev cluster.

Persistent resources such as Terraform state, ECR, Route 53, ACM certificates, GitHub OIDC configuration, and budgets remain in the same AWS account.

AWS Organizations and multi-account IAM Identity Center are not used.

Human access uses MFA and temporary credentials. Long-lived AWS access keys are not permitted.

## Consequences

The project keeps the AWS setup and cost model small enough for one engineer to operate.

Dev and prod can reuse the same Terraform modules without requiring cross-account role assumption.

Terraform state separation prevents a normal dev destroy from targeting prod state.

The design still exercises IAM roles, GitHub OIDC, EKS Pod Identity, VPC isolation, GitOps promotion, and environment-specific infrastructure.

The main cost is weaker isolation than separate AWS accounts provide.

An AWS account is a stronger security and blast-radius boundary than a VPC or IAM naming convention. A sufficiently privileged identity or incorrect account-wide policy could affect both dev and prod.

The project also does not exercise AWS Organizations, service control policies, or centralized multi-account IAM Identity Center administration.

Those limitations must not be described as equivalent to a production multi-account banking environment.

## Rejected alternatives

### Three accounts managed through AWS Organizations

Use separate shared, dev, and prod accounts under AWS Organizations with IAM Identity Center for human access.

This provides stronger blast-radius isolation, centralized identity management, and experience with service control policies and cross-account IAM.

It was rejected for this project because the additional account-management surface is not required for the main learning goals and conflicts with the current promotional-credit and cost constraints.

### Three independent AWS accounts

Keep shared, dev, and prod in separate accounts without AWS Organizations.

This preserves account-level isolation while avoiding an organization.

It was rejected because it makes human access, Terraform bootstrap, ECR sharing, Route 53 access, and other cross-account trust relationships more complicated without providing the centralized controls that normally justify a multi-account design.

For this project, that complexity would consume time without materially improving the core EKS, Terraform, GitOps, DevSecOps, and SRE exercises.

## Revisit when

Reconsider the single-account model if any of these become requirements:

- production needs an account-level security boundary from development
- service control policies are required
- centralized multi-account workforce access becomes a learning goal
- several engineers or teams need separate administrative boundaries
- promotional-credit preservation is no longer a constraint
- the project is extended specifically to demonstrate AWS Organizations and multi-account governance
