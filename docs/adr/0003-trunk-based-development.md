# ADR 0003: Use trunk-based development

## Status

Accepted

## Context

AS Bank needs a branching model that keeps `main` deployable while allowing application, infrastructure, and GitOps changes to be reviewed before merge.

The project promotes immutable image digests through environments rather than maintaining long-lived release branches. Development changes are expected to be small and merged frequently.

A branching model with several long-lived branches would add merge and synchronization work without creating a stronger deployment control. Production promotion is controlled through the GitOps pull request and approval process instead.

The repositories still need short-lived working branches so protected `main` is never changed directly.

## Decision

Use trunk-based development with `main` as the only long-lived branch.

Changes are made on short-lived `feat/`, `fix/`, `chore/`, `docs/`, `ci/`, or `refactor/` branches and merged through pull requests with required status checks.

Do not use `develop`, `release/*`, or `hotfix/*` branches.

Production release control stays in the GitOps promotion process rather than in a separate release branch.

## Consequences

`main` stays the single integration point for each repository.

Short-lived branches reduce long-running divergence and make merge conflicts less likely.

Code integration and environment promotion remain separate. A change merges to `main`, produces an immutable image digest, and is promoted through GitOps rather than through a release branch.

The cost is that branches must stay small and short-lived. Large changes that remain open for a long time become harder to review and merge.

The model also relies on strong pull request checks because there is no secondary long-lived branch acting as a stabilization buffer.

## Rejected alternatives

### GitFlow

Use `develop`, feature branches, release branches, hotfix branches, and `main`.

GitFlow provides explicit release and stabilization branches and can work well when several released versions must be maintained at the same time.

It was rejected because AS Bank promotes immutable artifacts rather than maintaining long release stabilization branches. The extra branches would add merge and synchronization work without improving the GitOps production approval control.

### Direct commits to main

Make every change directly on `main` without short-lived branches.

This is a simpler form of trunk-based development and removes branch management entirely.

It was rejected because `main` is protected and changes must pass pull request review and required status checks before becoming deployable.

## Revisit when

Reconsider this model if AS Bank needs to maintain several released versions at the same time or requires long stabilization periods before production releases.
