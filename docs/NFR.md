# AS Bank Non-Functional Requirements

AS Bank is a learning platform built with synthetic data. These requirements define the targets used to drive architecture, testing, recovery, capacity, and cost decisions.

The targets are intentionally smaller than those of a real bank. They exist so the platform can be measured against explicit requirements rather than vague expectations.

## Availability

Customer-facing APIs must achieve 99.5% availability while an environment is active.

Intentional teardown of dev, QA, or prod infrastructure does not count as downtime. Once an environment is declared active, unplanned loss of service does.

At 99.5% availability, a continuously running service has an error budget of about 3 hours 36 minutes per 30-day month.

The transfer API is the primary service used to measure this target.

## Recovery

### Recovery Time Objective

RTO: 60 minutes.

Critical customer-facing services must be recoverable within 60 minutes after a major infrastructure, platform, or database failure.

The actual recovery time will be measured during the disaster recovery stage.

### Recovery Point Objective

RPO: 5 minutes.

Critical transactional data must be recoverable to a point no more than five minutes before the failure.

RDS point-in-time recovery will be tested during the disaster recovery stage and the achieved RPO recorded.

## Workload

The expected application workload is:

- sustained normal load: 20 requests per second
- short-duration peak load: 100 requests per second
- transfer workload: at least 20 completed transactions per second

These are engineering test targets, not claims about real banking traffic.

Load testing must verify both throughput and latency. Meeting the request rate while violating the latency target is a failure.

## Latency

The transfer API must maintain a p95 response time below 500 ms.

This means at least 95% of measured transfer requests must complete in less than 500 ms under the defined workload.

Customer-facing read APIs should maintain a p95 response time below 300 ms.

The transfer latency budget includes application processing, service-to-service calls, database work, and network overhead.

Outbound calls must use explicit connection and read timeouts so a slow dependency cannot consume the request budget indefinitely.

## Security and compliance assumptions

AS Bank uses synthetic data only.

No real customer data, payment card data, production credentials, or regulated financial information may be stored or processed.

The project does not claim certification or compliance with PCI DSS, FCA, PRA, ISO 27001, SOC 2, or another regulatory framework.

Banking-style controls are still required where they support the learning goals. These include:

- least-privilege IAM
- MFA for human AWS access
- temporary AWS credentials rather than long-lived access keys
- OAuth2 and JWT-based authentication
- role and resource-ownership authorization
- secrets kept outside Git and container images
- encryption in transit
- vulnerability, dependency, IaC, image, and secret scanning
- signed container images
- Kubernetes admission controls
- auditable infrastructure and deployment changes

Every public README must state that AS Bank is a learning project using synthetic data and must not present the work as production banking experience.

## Team size

The platform is designed, built, and operated by one engineer.

Automation should remove repetitive operational work where practical.

Components that require dedicated specialist teams to operate safely are not justified unless a later requirement changes that decision.

This assumption describes the project. It does not imply that a production banking platform should use the same staffing model.

## Cost

Normal gross AWS spend must remain below $30 per month.

Gross cost means AWS resource cost before promotional credits are applied.

The architecture must not depend on promotional credits to appear inexpensive.

Persistent resources should remain near the idle-cost baseline defined in the project specification.

Dev and prod compute, databases, NAT gateways, load balancers, and paid endpoints must be destroyed when they are not required.

AWS Budgets and email alerts must be configured before the first billable infrastructure deployment.

Cost Explorer must be checked after teardown to confirm that no unintended ephemeral resources remain.

## Acceptance targets

| Requirement          | Target                            |
| -------------------- | --------------------------------- |
| Availability         | 99.5% while environment is active |
| RTO                  | 60 minutes or less                |
| RPO                  | 5 minutes or less                 |
| Normal load          | 20 requests/second                |
| Peak load            | 100 requests/second               |
| Transfer throughput  | At least 20 transactions/second   |
| Transfer latency     | p95 below 500 ms                  |
| Read API latency     | p95 below 300 ms                  |
| Data                 | Synthetic only                    |
| Team size assumption | 1 engineer                        |
| Gross AWS spend      | Below $30/month                   |

If later measurements show that a target is unrealistic, changing it requires an explicit decision and a recorded reason. The implementation must not silently redefine the requirement.
