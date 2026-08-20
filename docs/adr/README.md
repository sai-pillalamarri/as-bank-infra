# Architecture Decision Records

Architecture decisions for AS Bank are recorded when the decision is made, not reconstructed later.

Files use this naming scheme:

`NNNN-short-title.md`

Numbers are sequential and are never reused.

The normal status flow is:

`Proposed -> Accepted -> Superseded`

An ADR is not edited to hide an old decision. If the architecture changes, write a new ADR and mark the old one as superseded.

Every ADR must include:

- the problem and relevant constraints
- the decision
- consequences and costs
- at least two rejected alternatives
- the reason each alternative was rejected
- a concrete condition that would cause the decision to be revisited

ADRs are drafted with enough technical detail to support the decision, then rewritten in the author's own words before they are merged.
