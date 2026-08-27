Session Log

Session 1 — 2026-08-20

Stage: 0 (Foundations)
Done: NFR document; three fresh public repositories; protected main branches; pre-commit hooks; ADR process; ADR 0001 repository split; ADR 0002 single-account AWS strategy
In progress: None
Blocked on: None
Next: Start Stage 1 with the customer-service walking skeleton
Branch: main
Decisions: Use three repositories (ADR 0001); use one standalone AWS account with environment-level isolation (ADR 0002)
Files changed: docs/NFR.md, docs/adr/README.md, docs/adr/0000-template.md, docs/adr/0001-repository-split.md, docs/adr/0002-single-account-aws-strategy.md, .githooks/pre-commit, docs/AS_BANK_PROJECT.md, docs/SESSION-LOG.md
Gotchas: GitHub Free requires public repositories for branch protection; core.hooksPath must be configured locally for versioned Git hooks

Session 2 — 2026-08-21

Stage: 1 (Walking skeleton)

Done: Verified Java 21, Maven 3.9.7, Docker, and Docker Compose; created feat/customer-service-skeleton; created the customer-service Maven module in IntelliJ; configured Spring Boot 3.5.16 with Java 21 and Stage 1 dependencies; aligned IntelliJ and Maven to Java 21; created the customer-service implementation, PostgreSQL/Flyway configuration, local mock OAuth2 issuer configuration, and Docker Compose setup; mock OAuth2 issuer /isalive endpoint verified with HTTP 200

In progress: customer-service walking skeleton implementation exists but has not yet passed the final mvn clean install and runtime verification

Blocked on: None; previous Docker Compose failure was caused by nonexistent mock OAuth2 image tag 3.1.4 and was resolved by using ghcr.io/navikt/mock-oauth2-server:4.0.0

Next: Run docker compose ps, then cd customer-service && mvn clean install; if successful, start the service and verify authentication, authorization, PostgreSQL/Flyway, correlation IDs, API response, Actuator histogram buckets, and the customer lookup business metric

Branch: feat/customer-service-skeleton

Decisions: Use IntelliJ IDEA for backend development while Maven and Git remain authoritative; use Spring Boot 3.5.16 to remain on the specified Spring Boot 3.x line; use NAV mock-oauth2-server 4.0.0 for the local issuer; no new ADR written

Files changed: .gitignore, compose.yaml, customer-service/pom.xml, customer-service/src/main/java/com/asbank/customer/\*\*, customer-service/src/main/resources/application.yml, customer-service/src/main/resources/application-local.yml, customer-service/src/main/resources/db/migration/V1create_customers.sql, customer-service/src/main/resources/db/local/Rseed_local_customers.sql, customer-service/src/test/java/com/asbank/customer/customer/CustomerRepositoryIntegrationTest.java, customer-service/local/mock-oauth2/config.json

Gotchas: IntelliJ initially generated Java 23 settings and Maven ran on JDK 23 until the IDE and environment were aligned to Java 21; IntelliJ Spring Initializr only offered Spring Boot 4.x so the service was created as a plain Maven module; Docker Desktop must be running before Compose and Testcontainers; mock-oauth2-server tag 3.1.4 does not exist; .idea/ must remain ignored

Session 3 — 2026-08-21

Stage: 2 (AWS foundation)

Done: Stage 1 walking skeleton completed and verified; customer-service implemented with PostgreSQL 16, Flyway, OAuth2 resource-server security, ownership checks, correlation IDs, RFC 7807 errors, Actuator histogram buckets, business metrics, and Testcontainers; customer-service merged through PR #3; React 19 frontend implemented with TypeScript, Vite, React Router, Tailwind, shadcn/ui, runtime config, secured customer-service integration, banking-style UI, ESLint, Prettier, and production build; frontend-to-customer-service runtime path verified with Alex Morgan / ACTIVE; frontend merged through PR #4

In progress: Stage 2 has not started

Blocked on: None

Next: Begin Stage 2 — AWS foundation with AWS account access, MFA, Budgets, GitHub OIDC, and Terraform Layer 0

Branch: main

Decisions: Customer-service and frontend were merged as separate PR checkpoints; use squash merge because merge commits are disabled; account-service and transaction-service remain scheduled for Stage 7; AWS foundation now precedes CI and supply chain so ECR and GitHub OIDC exist before the release pipeline; no new ADR written

Files changed: .gitignore, .githooks/pre-commit, compose.yaml, customer-service/, frontend/, docs/AS_BANK_PROJECT.md, docs/SESSION-LOG.md

Gotchas: Local Java reports Asia/Calcutta on Windows, so customer-service tests use UTC and local runtime currently uses -Duser.timezone=UTC; mock OAuth tokens expire and require local-secret for client_credentials; merge commits are disabled so use squash merge; frontend Prettier must run from the frontend package scope; Maven target/ and frontend dist/ must remain ignored

Session 4 — 2026-08-21

Stage: 2 (AWS foundation)
Done: Verified new AWS account access; enabled root MFA; created as-bank-operator with MFA; verified the operator has no static access keys; authenticated locally with aws login temporary credentials using profile as-bank; selected us-east-1 as the primary workload region; merged documentation PR #6 recording the Stage 2/3 reorder and ADR 0003 trunk-based development; created the initial Terraform bootstrap configuration; created and verified the as-bank-monthly-cost AWS Budget through Terraform with a $30 monthly limit, credits excluded, a $0.01 test alert, and 80%/100% actual-cost alerts; verified no existing S3 buckets, ECR repositories, Route 53 hosted zones, GitHub OIDC providers, or AS Bank IAM roles exist in the new account
In progress: Terraform Layer 0 bootstrap uses local state and currently contains the verified Budget only; remaining persistent Layer 0 resources have not been implemented
Blocked on: None
Next: Implement the remaining Layer 0 Terraform in one batch: S3 state bucket, ECR repositories, Route 53 hosted zone, GitHub OIDC provider, application-release role, infrastructure-plan role, infrastructure-apply role, human STS operator role, and outputs; then run fmt/validate/plan, review and apply once, verify the AWS resources, add the S3 backend configuration, and migrate local state with terraform init -migrate-state
Branch: feat/aws-foundation
Decisions: Use us-east-1 as the primary workload region; use aws login temporary credentials for the human operator with no access keys; bootstrap Layer 0 from the workstation with local Terraform state and migrate it to S3 after the state bucket exists; manage AWS Budgets through Terraform and create the Budget before other billable infrastructure; use trunk-based development (ADR 0003)
Files changed: docs/AS_BANK_PROJECT.md, docs/SESSION-LOG.md, docs/adr/0003-trunk-based-development.md, .gitignore, terraform/bootstrap/versions.tf, terraform/bootstrap/providers.tf, terraform/bootstrap/variables.tf, terraform/bootstrap/budget.tf, terraform/bootstrap/.terraform.lock.hcl
Gotchas: The old default AWS CLI profile still contains static credentials for the old AWS account, so Stage 2 commands must use profile as-bank or AWS_PROFILE=as-bank; Bash uses \ for multiline commands but PowerShell does not; AWS Budgets may return no ThresholdType for percentage notifications because percentage is the default; the $0.01 test notification is returned explicitly as ABSOLUTE_VALUE; never commit Terraform local state, terraform.tfvars, AWS account IDs, or credentials

Session 5 — 2026-08-24

Stage: 2 (AWS foundation)
Done: Completed and verified Terraform Layer 0 with the S3 state bucket, four ECR repositories, Route 53 hosted zone, GitHub OIDC provider, application-release role, infrastructure-plan role, infrastructure-apply role, and MFA-protected operator role; applied the reviewed Layer 0 plan with 20 resources added and no destroys; verified S3 versioning, AES256 encryption, public-access blocking, and native locking; verified ECR immutable tags and scan-on-push; delegated aslearnings.online from Hostinger to Route 53 and verified the new nameservers through Google and Cloudflare DNS; migrated Terraform bootstrap state from local state to S3 and verified a zero-drift plan; removed direct AdministratorAccess from as-bank-operator and moved administrative access behind the MFA-protected STS role; removed the old static default AWS CLI credentials and verified the operator has zero IAM access keys; merged PR #7 as commit a665272
In progress: AWS foundation implementation is merged to main; only delivery of the $0.01 AWS Budget test alert remains unverified because AWS still reports $0.00 actual spend
Blocked on: AWS Budgets has not recorded enough actual spend to cross the $0.01 test threshold; no implementation blocker
Next: When AWS records more than $0.01 actual spend, verify the Budget alert email and mark Stage 2 complete; then begin Stage 3 — CI and supply chain in as-bank-app
Branch: main
Decisions: Keep Hostinger as registrar and Route 53 as authoritative DNS; use S3 native Terraform state locking; keep human administrative permissions behind the MFA-protected STS operator role; defer Budget email delivery verification until AWS records billable usage; no new ADR written
Files changed: .gitignore, terraform/bootstrap/.terraform.lock.hcl, terraform/bootstrap/backend.tf, terraform/bootstrap/budget.tf, terraform/bootstrap/data.tf, terraform/bootstrap/ecr.tf, terraform/bootstrap/iam.tf, terraform/bootstrap/locals.tf, terraform/bootstrap/oidc.tf, terraform/bootstrap/outputs.tf, terraform/bootstrap/provider.tf, terraform/bootstrap/route53.tf, terraform/bootstrap/state.tf, terraform/bootstrap/variables.tf, terraform/bootstrap/versions.tf, docs/AS_BANK_PROJECT.md, docs/SESSION-LOG.md
Gotchas: aws login sessions expire and require reauthentication; Terraform worked reliably after exporting temporary credentials from as-bank-operator-role; adding the S3 backend requires terraform init -migrate-state; AWS Budgets may return no ThresholdType for percentage notifications; Budget ActualSpend was still $0.00; DNS delegation may briefly return cached nameservers after changing the registrar

Session 6 — 2026-08-25

Stage: 3 (CI and supply chain)
Done: Completed and verified Stage 3; added path-aware application CI with Maven tests, frontend lint/build, SonarQube Cloud quality gates, Trivy filesystem scanning, Gitleaks, ZAP baseline DAST, and required PR gate; added negative JWT security integration tests covering expired token, wrong issuer, ID token, wrong client ID, tampered signature, missing role, and cross-customer access; added JaCoCo reporting; configured separate SonarQube Cloud projects for customer-service and frontend; enabled Dependabot vulnerability alerts, automated security fixes, and weekly Maven/npm/GitHub Actions updates; enabled strict branch protection requiring PR gate; added pinned multi-stage customer-service and frontend container builds; added main-only release workflow using GitHub OIDC, ECR, Trivy image scanning, Syft SBOM, and Cosign keyless signing; fixed missing AWS_APPLICATION_RELEASE_ROLE_ARN repository variable; successful release run 32855885460 pushed and verified customer-service digest sha256:578627f734ea4d1ae81244a40441a0dd9dcf3c6a04b060ffe05771aad81c8c73 and frontend digest sha256:efdd91d5e970bfb34399545bbc8c6fc2b3783d1c6fabbef1291dc95364ffa032; signed SPDX SBOM attestations were created; PR #15 proved an injected Log4j CVE fails Trivy and the required PR gate; PR #16 proved removing token_use validation makes SecurityIntegrationTest.rejectsIdTokenAtApi fail with expected 401 versus actual 404 and blocks the PR; both proof PRs and branches were deleted; as-bank-app main verified clean and synchronized
In progress: None; Stage 3 is complete and Stage 4 has not started
Blocked on: None; Stage 2 Budget test-alert email delivery remains deferred until AWS records enough actual spend to cross the $0.01 threshold
Next: Switch to as-bank-infra, capture git branch/status/log, then begin Stage 4 — Network and cluster from the existing Terraform structure
Branch: main (as-bank-app)
Decisions: Use separate SonarQube Cloud projects for customer-service and frontend with the built-in Sonar way quality gate; keep Dependabot PR CI but suppress duplicate dependabot/\*\* push runs; retain signed SPDX SBOM attestations but do not block release on cosign verify-attestation because that command hung, while cosign verify remains a blocking release check; no new ADR written
Files changed: .github/dependabot.yml, .github/workflows/ci.yml, .github/workflows/reusable-java-ci.yml, .github/workflows/release.yml, .github/workflows/reusable-image-release.yml, customer-service/.dockerignore, customer-service/Dockerfile, customer-service/pom.xml, customer-service/sonar-project.properties, customer-service/src/test/java/com/asbank/customer/customer/SecurityIntegrationTest.java, frontend/.dockerignore, frontend/Dockerfile, frontend/sonar-project.properties, frontend nginx runtime configuration
Gotchas: AWS_APPLICATION_RELEASE_ROLE_ARN was missing and caused configure-aws-credentials to fail before OIDC; the login user cannot iam:GetRole by design, so the release-role ARN was constructed locally from STS account identity and the known role name; cosign verify-attestation hung and the workflow required GitHub force-cancel; the first push of a newly created branch can trigger both application paths because the push before-SHA has no normal parent comparison, while PR and later push path filtering works correctly; intentional negative-test proof required git commit --no-verify because the local hook correctly rejected the weakened control; broad 12-digit account-ID redaction can accidentally alter unrelated SHA text

For Section 19, update it from the current Stage 2 status to the following state. The previous session log ends at Session 5, so this is Session 6.

Session 7 — 2026-08-27

Stage: 4 (Network and cluster)
Done: Verified the Karpenter destroy-order fix merged through PR #11; verified make up ENV=dev; proved Karpenter provisioned a Ready c7i-flex.large Spot node for a constrained workload and AWS reported InstanceLifecycle=spot; verified make down ENV=dev succeeded with the Karpenter workload still present; confirmed EKS, NAT Gateway, paid interface endpoints, active EC2 nodes, and the generated Karpenter instance profile were removed without manual cleanup; Cost Explorer showed no positive Stage 4 service spend after teardown; Stage 4 exit criteria completed
In progress: Stage 4 documentation closeout; updated AS_BANK_PROJECT.md and SESSION-LOG.md content has been prepared, but the final repository diff has not yet been verified or committed
Blocked on: None; the Stage 2 AWS Budget test-alert email remains deferred until ActualSpend crosses $0.01
Next: Verify docs/AS_BANK_PROJECT.md and docs/SESSION-LOG.md with git diff --check and git diff, commit and push docs/stage4-closeout, merge the documentation PR, then begin Stage 5 — GitOps in as-bank-gitops
Branch: docs/stage4-closeout
Decisions: Stage 4 is complete; dev Karpenter uses Spot and prod uses On-Demand; bootstrap managed node groups use On-Demand; Karpenter runtime depends on the cluster module so Karpenter cleanup completes before its AWS access is removed; ADR 0004 remains the relevant layering/apply-model decision
Files changed: terraform/cluster/dev/main.tf, terraform/cluster/prod/main.tf, docs/AS_BANK_PROJECT.md, docs/SESSION-LOG.md
Gotchas: Operator STS sessions expire even while the aws login profile remains usable; Karpenter-generated instance profiles can be orphaned if controller credentials disappear before EC2NodeClass cleanup; the AWS Free account plan rejected t3.medium; Cost Explorer can remain estimated after teardown; Git Bash and native Windows Python handle /tmp differently; whole-file newline conversion caused noisy Markdown diffs, so preserve the canonical Markdown and avoid line-ending rewrite scripts

## Session 8 — 2026-08-27

Stage: 5 (GitOps)

Done: Completed and verified Stage 5; added Argo CD as Terraform-managed Layer 2 runtime infrastructure; implemented the app-of-apps structure with separate bootstrap, platform, and application trees for dev and prod; added and enforced GitOps manifest validation; verified Argo CD root, platform, and application Applications reached Synced and Healthy; verified the initial gitops-proof workload was reconciled from Git; merged a GitOps change and proved Argo advanced to the new Git revision and rolled the pod from version=stage5 to version=stage5-pr-proof without kubectl apply or manual Argo sync; verified make down ENV=dev completed successfully; confirmed no dev EKS cluster, NAT Gateway, paid interface endpoints, or running EC2 instances remained after teardown

In progress: Stage 5 documentation closeout; implementation and AWS teardown are complete, but the final documentation commit and PR have not yet been merged

Blocked on: None; the Stage 2 AWS Budget test-alert email remains deferred until ActualSpend crosses $0.01

Next: Commit and merge docs/stage5-closeout, then begin Stage 6 — Hardening with External Secrets Operator and EKS Pod Identity

Branch: docs/stage5-closeout

Decisions: Terraform owns the Argo CD installation and environment root Application; Argo CD owns the desired Kubernetes state from as-bank-gitops. Dev child Applications auto-sync while prod child Applications remain manual as already specified. No new ADR written

Files changed: as-bank-gitops/.github/workflows/validate.yml, as-bank-gitops/bootstrap/, as-bank-gitops/platform/, as-bank-gitops/apps/, as-bank-infra/.github/workflows/environment-up.yml, as-bank-infra/.github/workflows/environment-down.yml, as-bank-infra/.github/workflows/terraform-plan.yml, as-bank-infra/terraform/cluster/dev/, as-bank-infra/terraform/cluster/prod/, as-bank-infra/terraform/modules/argocd-runtime/, as-bank-infra/docs/AS_BANK_PROJECT.md, as-bank-infra/docs/SESSION-LOG.md

Gotchas: VS Code Prettier rewrites bare Helm expressions that start a YAML value, so those values must be quoted; Git Bash does not include watch by default; running set -e directly in an interactive Git Bash session can close the shell on failure; the Terraform plan workflow initially missed the outer fi around its cluster-only logic; the base as-bank-operator user intentionally cannot call iam:ListMFADevices and EKS access still requires the MFA-backed operator role

## Session 9 — 2026-08-28

Stage: 6 (Hardening)

Done: Completed and verified Stage 6; added External Secrets Operator with EKS Pod Identity and environment-scoped Secrets Manager access; proved a synthetic Secrets Manager value synchronized unchanged into a Kubernetes Secret; added Kyverno enforce-mode workload and image policies; integrated Kyverno with private ECR through Pod Identity; proved a signed AS Bank image was accepted and the same image copied without its Cosign signature was rejected; enabled Pod Security Admission at restricted:v1.35 and proved a root container was rejected; verified default ServiceAccount API access is denied; enabled VPC CNI NetworkPolicy enforcement; proved DNS egress remains allowed while arbitrary HTTPS egress and cross-namespace ingress are blocked; verified Argo CD remained Synced and Healthy; removed all temporary proof resources; completed make down ENV=dev and confirmed no dev EKS cluster, NAT Gateway, paid interface endpoints, EC2 instances, or dev cluster IAM roles remained

In progress: Stage 6 documentation closeout only; Section 19 and this session log are being prepared for the final documentation PR

Blocked on: None; the Stage 2 AWS Budget test-alert email remains deferred until ActualSpend crosses $0.01

Next: Verify the Stage 6 documentation diff, commit and merge docs/stage6-closeout, then begin Stage 7 — Full application with account-service and transaction-service

Branch: docs/stage6-closeout

Decisions: Stage 6 command-output proofs are sufficient evidence for the unsigned-image and root-container rejection controls; no new ADR written

Files changed: as-bank-infra/.github/workflows/environment-up.yml, as-bank-infra/.github/workflows/environment-down.yml, as-bank-infra/.github/workflows/terraform-plan.yml, as-bank-infra/terraform/cluster/dev/, as-bank-infra/terraform/cluster/prod/, as-bank-infra/terraform/modules/cluster/, as-bank-infra/terraform/modules/external-secrets-runtime/, as-bank-infra/terraform/modules/kyverno-runtime/, as-bank-gitops/apps/dev/, as-bank-gitops/platform/dev/, as-bank-gitops/platform/prod/, as-bank-infra/docs/AS_BANK_PROJECT.md, as-bank-infra/docs/SESSION-LOG.md

Gotchas: EKS kubeconfig must be refreshed after cluster recreation because the API endpoint changes; temporary STS operator-role credentials can expire during a long verification session; ECR contains Cosign/SBOM OCI artifacts alongside runnable images, so selecting the newest digest without filtering artifact type can return a signature artifact; customer-service uses named USER asbank with UID 10001, so kubelet required an explicit numeric runAsUser for the temporary runAsNonRoot proof workload; persistent S3 and DynamoDB gateway endpoints correctly remain after teardown and must not be mistaken for paid Layer 2 interface endpoints
