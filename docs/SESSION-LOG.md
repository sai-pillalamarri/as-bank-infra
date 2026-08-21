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
