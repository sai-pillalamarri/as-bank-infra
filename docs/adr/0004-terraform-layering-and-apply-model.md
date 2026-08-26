# ADR 0004: Use lifecycle-based Terraform layers and CI applies

## Status

Accepted

## Context

AS Bank uses one AWS account, but dev and prod must remain isolated by Terraform state, VPC, IAM, and Kubernetes cluster boundaries.

The infrastructure has different lifecycles.

Some resources must remain when no environment is running. The Terraform state bucket, ECR repositories, Route 53 hosted zone, GitHub OIDC provider, and CI roles are persistent.

Other resources are expensive while idle. EKS, worker nodes, NAT gateways, and interface VPC endpoints should exist only while an environment is active.

The network sits between those lifecycles. VPCs, subnets, route tables, Internet Gateways, and S3 and DynamoDB gateway endpoints have no meaningful idle hourly cost. Rebuilding them every session would add time without reducing spend.

A NAT gateway is logically a network resource but has an hourly charge. Interface endpoints also have an hourly charge. Their lifecycle therefore needs to follow the cluster rather than the persistent network.

QA does not need another VPC or EKS cluster. It shares the dev infrastructure and is isolated later through Kubernetes namespaces and application configuration.

Terraform changes also need an auditable execution path. Routine applies from an engineer's workstation would depend on local credentials and local tool versions and would not leave the same execution record as GitHub Actions.

Stage 4 also exposed a bootstrap problem. The original shared infrastructure apply role could manage Terraform state but could not modify the Layer 0 AWS resources that the main-branch apply workflow owns.

Two narrowly scoped bootstrap corrections were needed before the CI model was complete. The first created the environment-specific plan and apply roles plus the EC2 Spot service-linked role. The second gave the shared Layer 0 apply role the write permissions needed for future bootstrap changes on `main`.

## Decision

Use three Terraform lifecycle layers.

Layer 0 contains persistent account-wide resources and uses:

`bootstrap/terraform.tfstate`

Layer 1 contains persistent network resources. Dev and prod use separate state keys:

`network/dev/terraform.tfstate`

`network/prod/terraform.tfstate`

Layer 2 contains ephemeral cluster resources. Dev and prod use separate state keys:

`cluster/dev/terraform.tfstate`

`cluster/prod/terraform.tfstate`

QA shares the dev VPC and EKS cluster and therefore has no separate Terraform root or state.

Keep VPCs, subnets, route tables, Internet Gateways, and the S3 and DynamoDB gateway endpoints in Layer 1.

Put NAT gateways and paid interface endpoints in Layer 2 even though they are network resources. Their billing follows the cluster lifecycle, so they are destroyed with EKS.

Use reusable `network` and `cluster` child modules. Root configurations own the environment-specific remote state and values.

Keep Karpenter in Layer 2.

Terraform creates the AWS-side resources Karpenter needs, including its IAM roles and policies, interruption queue, and EventBridge rules.

The Karpenter controller is installed from the official Helm chart. The AS Bank `EC2NodeClass` and `NodePool` are installed from a small local Helm chart in the same Layer 2 Terraform state.

Dev Karpenter workloads use Spot capacity. Prod Karpenter workloads use On-Demand capacity.

The managed bootstrap node group uses On-Demand instances in both environments. Karpenter needs existing compute to run its controller, and the controller must not depend on nodes that Karpenter itself creates.

The first Layer 2 creation uses two Terraform applies against the same state.

The first apply sets `install_karpenter=false`. This creates EKS, the bootstrap node group, and the AWS-side Karpenter resources before Helm needs to contact the Kubernetes API.

The second apply sets `install_karpenter=true`. Once EKS is reachable, Terraform installs the Karpenter controller, `EC2NodeClass`, and `NodePool`.

Later `make up` runs check whether the EKS cluster already exists. If it does, the initial bootstrap phase is skipped and Terraform runs the full Layer 2 plan with Karpenter enabled.

Terraform execution follows the layer lifecycle.

Pull requests run formatting, validation, TFLint, Checkov, and Terraform plans.

Layer 0 and Layer 1 changes apply after merge to `main`.

Layer 2 creation and destruction use manual GitHub Actions workflows with an explicit `dev` or `prod` input.

`make up` and `make down` are thin wrappers around those manual workflows.

Routine Terraform applies do not run from a workstation.

Use separate dev and prod GitHub OIDC plan and apply roles for environment infrastructure.

Each environment role is limited to its own Terraform state paths and the AWS mutation surface required for that environment.

When an EKS cluster exists, the environment plan role receives read-only Kubernetes access so Terraform and Helm can inspect existing cluster state during a pull-request plan.

The environment apply role receives the Kubernetes access needed to install and change Helm-managed resources.

Layer 2 depends on Layer 1 remote state.

If the Layer 1 state does not exist, the initial cluster plan is deferred.

If Layer 1 exists but EKS is currently down, the pull-request workflow plans Layer 2 with `install_karpenter=false` so Helm does not try to contact a missing Kubernetes API.

If EKS is running, the pull-request workflow plans the full Layer 2 state with Karpenter enabled.

The original Layer 0 bootstrap required a workstation apply because the state bucket and GitHub OIDC roles did not exist yet.

Stage 4 later required two bootstrap corrections.

The first created the environment-specific CI roles and the EC2 Spot service-linked role.

The second added a scoped Layer 0 write policy to the shared infrastructure apply role after the main-branch workflow was found unable to modify bootstrap resources.

Both corrections used the MFA-protected operator role. Each change was reviewed through a saved Terraform plan before apply and followed by a zero-drift plan.

No further workstation apply is part of the normal operating model.

## Consequences

Destroying Layer 2 removes EKS, compute, NAT gateways, paid interface endpoints, and the Karpenter runtime without touching the persistent VPC or another environment.

Recreating an environment is faster because Layer 1 does not need to be rebuilt every session.

Separate dev and prod state limits Terraform blast radius. A destroy against `cluster/dev` cannot destroy the prod cluster or either persistent network state.

The free gateway endpoints stay available without adding idle hourly cost.

Layer 2 depends on Layer 1 state, so the first cluster plan cannot run until its network state exists.

Once Layer 1 exists, pull-request CI can still plan the AWS and EKS resources while the cluster is down. A full Helm-aware plan becomes possible once EKS is running.

Dev uses one NAT gateway to control cost. Private-subnet internet egress therefore depends on one availability zone while dev is active.

Prod uses one NAT gateway per availability zone while the prod cluster layer is active.

The two-phase first `make up` makes initial cluster creation slightly more complex, but it avoids configuring Helm against an EKS API that does not exist yet.

The cost of the design is more Terraform roots, backend keys, CI roles, remote-state dependencies, and workflow logic than a single-state design.

CI IAM policies need maintenance when later Terraform changes introduce additional AWS API operations.

The Stage 4 bootstrap workstation applies are exceptions to the normal operating model. They remain documented so they do not become precedent for routine local applies.

## Rejected alternatives

### One Terraform state for all infrastructure

Store bootstrap, networking, dev, prod, and cluster resources in one state.

This would reduce the number of roots and remote-state references.

It was rejected because a cluster teardown would operate from the same state as persistent and production resources. The larger blast radius is not justified by the smaller Terraform structure.

### Put NAT gateways and interface endpoints in the persistent network layer

Keep all networking resources together according to AWS resource type.

This would make the network module conceptually simpler.

It was rejected because NAT gateways and interface endpoints have hourly charges even when no cluster is using them. Leaving them in Layer 1 would break the project's idle-cost target.

### Separate Terraform infrastructure for QA

Create a third VPC, Terraform state, and EKS cluster for QA.

This would give QA the same infrastructure isolation as prod.

It was rejected because QA is an application promotion environment, not a separate infrastructure lifecycle in this project. Another EKS cluster and its supporting resources would add cost and operational work without serving a current requirement.

### Install Karpenter outside the Layer 2 Terraform state

Install Karpenter manually or manage its runtime from a separate Terraform state.

This would avoid the two-phase first apply.

It was rejected because Karpenter follows the same lifecycle as the EKS cluster. A separate state or manual installation would create another lifecycle boundary without a corresponding operational need.

### Routine workstation applies

Run `terraform apply` locally using the MFA-protected operator role.

This is technically simpler and remains useful for exceptional bootstrap recovery.

It was rejected as the routine path because local execution depends on workstation credentials and tool versions and provides a weaker shared audit trail than GitHub Actions with OIDC.

## Revisit when

Reconsider the layer boundaries if persistent network resources develop meaningful idle cost or if rebuilding them becomes necessary for security or isolation.

Reconsider QA sharing dev infrastructure if QA requires independent infrastructure testing, independent scaling, or a separate security boundary.

Reconsider the two-phase Karpenter bootstrap if the Terraform or Helm provider model changes so the Kubernetes provider can be configured safely before the EKS API exists.

Reconsider the CI role split if the project moves to separate AWS accounts where the account boundary replaces some of the current environment-level IAM controls.
