---
name: devops-engineer
description: "Produce an infrastructure and DevOps design document for a project or feature. Use this skill when the user says 'devops phase', 'infrastructure design', 'write the infra plan', 'design the pipeline', 'set up CI/CD', or hands off for deployment and infrastructure planning. Also triggers for feature-level infra impact like 'this feature needs a new service' or 'we need a new environment variable'. Reads system-architecture.md as upstream context and produces infrastructure-design.md covering IaC strategy, environment topology, CI/CD pipeline design, observability setup, and deployment strategy. Always invoke this skill after tech-lead has produced system-architecture.md and before senior-developer begins implementation. For feature-level work, invoke after tech-lead has accepted the feature's technical-spec.md."
---

# DevOps Engineer Skill

Translate the accepted system architecture into a concrete infrastructure and delivery
plan. This skill owns everything between "code is written" and "code is running in
production" — environment topology, deployment pipelines, IaC strategy, observability,
and operational conventions.

This skill has two modes. Identify which applies before proceeding.

**Project Mode** — Produces `docs/project/infrastructure-design.md` for the full system.
Triggered when no feature ID is referenced and a project-level infra plan is needed.

**Feature Mode** — Produces `docs/features/{F-NNNN}-{slug}/specs/infrastructure-design.md`
for a feature that introduces infra changes (new service, new env vars, new pipeline stage, etc.).
Triggered when a specific feature's infra impact needs to be documented.

---

## Project Mode

### P-Step 1 — Read the Project Package

Before doing anything else, read in this order:

1. `docs/project/system-architecture.md` — confirm it exists and status is `Accepted`
2. `docs/project/project-requirements-document.md` — constraints, NFRs, and scale expectations
3. `docs/adr/` — any existing ADRs relevant to infrastructure decisions
4. Any additional context provided by the user (cloud provider, existing tooling, team constraints)

If `system-architecture.md` does not exist, stop and inform the user.
The tech-lead must complete Project Mode before this skill can proceed.

---

### P-Step 2 — Identify ADR Trigger Points

Before designing anything, scan for decisions that require explicit evaluation:

| Signal                                                                            | Action                            |
| --------------------------------------------------------------------------------- | --------------------------------- |
| Multiple viable IaC tools with non-obvious tradeoffs (Terraform vs CDK vs Pulumi) | Flag for ADR                      |
| Container orchestration choice (ECS vs EKS vs App Service)                        | Flag for ADR                      |
| CI/CD platform choice if not already established                                  | Flag for ADR                      |
| Multi-region vs single-region deployment strategy                                 | Flag for ADR if non-obvious       |
| Secrets management approach                                                       | Flag for ADR if non-trivial       |
| Decision clearly mandated by system-architecture.md constraints                   | Decide inline, document rationale |

List all ADR triggers to the user and resolve them before finalizing the design.

---

### P-Step 3 — Write infrastructure-design.md

Write to `docs/project/infrastructure-design.md`.

Follow the **Project Infrastructure Design Template** section below exactly.

Scope:

- **In scope:** IaC strategy, environment topology, CI/CD pipeline design, secrets management,
  observability setup, deployment strategy, DR and backup conventions.
- **Out of scope:** Application code, business logic, feature-level data models.
  Stack and service boundary decisions → defer to `system-architecture.md`.

---

### P-Step 4 — Self-Check Before Presenting

- [ ] Every service in system-architecture.md has a corresponding deployment target
- [ ] All environments (dev, staging, prod) are defined with their differences documented
- [ ] CI/CD pipeline covers all stages: build, test, security scan, deploy, smoke test
- [ ] Secrets management approach is defined — no hardcoded credentials anywhere
- [ ] Observability covers logging, metrics, and alerting for each service
- [ ] Deployment strategy handles zero-downtime for production
- [ ] DR and backup strategy covers all stateful components
- [ ] ADR trigger points were resolved before document was finalized
- [ ] No decisions contradict system-architecture.md

---

### P-Step 5 — Save and Present

Output path:

- `docs/project/infrastructure-design.md`

---

## Feature Mode

### F-Step 1 — Read the Feature and Project Package

Before doing anything else, read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` — confirm Tech Lead phase is `✅ Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` — infra requirements for this feature
3. `docs/project/infrastructure-design.md` — existing infra conventions to follow
4. `docs/project/system-architecture.md` — service boundaries and stack context

If Tech Lead phase is not `✅ Accepted`, stop and inform the user. Do not proceed.

If `docs/project/infrastructure-design.md` exists, this feature's infra changes must
extend it — not contradict or duplicate it.

---

### F-Step 2 — Identify Infra Impact

Determine what infrastructure changes this feature requires:

| Signal                             | Impact                                                  |
| ---------------------------------- | ------------------------------------------------------- |
| New microservice or container      | New deployment unit, pipeline stage, service mesh entry |
| New database or schema             | Migration strategy, connection string, backup inclusion |
| New environment variable or secret | Secrets manager entry, pipeline injection               |
| New external integration           | Firewall rule, API key management, timeout config       |
| New async queue or topic           | Broker config, DLQ strategy                             |
| No infra changes                   | Confirm and skip — feature does not require this phase  |

If no infra changes are needed, inform the user and mark the DevOps phase as `❌ Skipped`
in the feature README.md with the reason noted.

---

### F-Step 3 — Write infrastructure-design.md

Write to `docs/features/{F-NNNN}-{slug}/specs/infrastructure-design.md`.

Follow the **Feature Infrastructure Design Template** section below exactly.

---

### F-Step 4 — Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | DevOps phase accepted | infrastructure-design.md written |
```

Update the Phase Tracker:

- `DevOps` → `✅ Accepted`
- Update `infrastructure-design.md` row in Artifact Index to `✅ Accepted`

---

### F-Step 5 — Self-Check Before Presenting

- [ ] Every infra change identified in F-Step 2 is covered in the document
- [ ] All changes are consistent with docs/project/infrastructure-design.md conventions
- [ ] Secrets and environment variables follow the project's established secrets management approach
- [ ] Deployment steps are concrete and ordered — not high-level guidance
- [ ] Rollback procedure is defined for every deployment change
- [ ] No decisions contradict system-architecture.md or project infrastructure-design.md

---

### F-Step 6 — Save and Present

Output paths:

- `docs/features/{F-NNNN}-{slug}/specs/infrastructure-design.md` (new)
- `docs/features/{F-NNNN}-{slug}/README.md` (updated)

---

## Project Infrastructure Design Template

```markdown
# Infrastructure Design

**Project:** {Project Name}
**Status:** Accepted
**Author:** devops-engineer
**Date:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD
**Depends On:** [ADR-NNNN list, or "No ADRs required"]
**Upstream:** docs/project/system-architecture.md

---

## 1. Overview

2–3 paragraphs. Summarize the infrastructure approach.
Answer: _"How is the system deployed, operated, and maintained?"_

---

## 2. Cloud Provider and IaC Strategy

| Concern                  | Choice | Rationale |
| ------------------------ | ------ | --------- |
| Cloud provider           | ...    | ...       |
| IaC tooling              | ...    | ...       |
| State management         | ...    | ...       |
| Module / stack structure | ...    | ...       |

---

## 3. Environment Topology

Define each environment and how it differs from production.

| Environment | Purpose | Scale | Auto-Deploy | Approval Required |
| ----------- | ------- | ----- | ----------- | ----------------- |
| dev         | ...     | ...   | Yes / No    | Yes / No          |
| staging     | ...     | ...   | Yes / No    | Yes / No          |
| prod        | ...     | ...   | Yes / No    | Yes / No          |

### Environment Differences

Document any meaningful differences between environments beyond scale:

- Feature flags, config overrides, external service mocking, data seeding, etc.

---

## 4. Deployment Targets

For each service in system-architecture.md, define its deployment target.

| Service | Target                                          | Runtime | Scaling Strategy |
| ------- | ----------------------------------------------- | ------- | ---------------- |
| ...     | ECS Fargate / Lambda / EC2 / App Service / etc. | ...     | ...              |

---

## 5. CI/CD Pipeline Design

### Pipeline Stages

| Stage             | Trigger               | Tools | Gate Condition       |
| ----------------- | --------------------- | ----- | -------------------- |
| Build             | Push to branch        | ...   | Compilation succeeds |
| Unit Test         | Build success         | ...   | All tests pass       |
| Security Scan     | Build success         | ...   | No critical CVEs     |
| Integration Test  | Merge to main         | ...   | All tests pass       |
| Deploy to Staging | Integration test pass | ...   | Automatic            |
| Smoke Test        | Staging deploy        | ...   | All smoke tests pass |
| Deploy to Prod    | Manual approval       | ...   | Approval received    |
| Post-Deploy Smoke | Prod deploy           | ...   | All smoke tests pass |

### Branching Strategy

- Main branch: ...
- Feature branches: ...
- Release tagging: ...
- Hotfix flow: ...

---

## 6. Secrets Management

| Secret Type               | Storage | Injection Method | Rotation |
| ------------------------- | ------- | ---------------- | -------- |
| DB credentials            | ...     | ...              | ...      |
| API keys                  | ...     | ...              | ...      |
| JWT signing keys          | ...     | ...              | ...      |
| Service-to-service tokens | ...     | ...              | ...      |

**Convention:** No secrets in source code, environment files committed to VCS,
or CI/CD pipeline plaintext variables. All secrets injected at runtime from the
designated secrets manager.

---

## 7. Observability

### Logging

- Log format: ...
- Correlation ID: ...
- Log aggregation: ...
- Retention policy: ...

### Metrics

- Metrics platform: ...
- Key metrics per service: ...
- Dashboard conventions: ...

### Alerting

| Alert               | Condition                 | Severity    | Notification Channel |
| ------------------- | ------------------------- | ----------- | -------------------- |
| High error rate     | Error rate > X% for Y min | 🔴 Critical | ...                  |
| Latency degradation | p99 > Xms for Y min       | 🟡 Warning  | ...                  |
| Resource exhaustion | CPU/Memory > X%           | 🟡 Warning  | ...                  |

---

## 8. Deployment Strategy

| Service Type        | Strategy                      | Rationale |
| ------------------- | ----------------------------- | --------- |
| Stateless services  | Blue/Green / Rolling / Canary | ...       |
| Stateful services   | ...                           | ...       |
| Database migrations | ...                           | ...       |

### Rollback Procedure

1. ...
2. ...

---

## 9. Disaster Recovery and Backup

| Component      | Backup Strategy | RTO | RPO | Recovery Procedure |
| -------------- | --------------- | --- | --- | ------------------ |
| Primary DB     | ...             | ... | ... | ...                |
| Object storage | ...             | ... | ... | ...                |

---

## 10. Key Infrastructure Decisions

| Decision | Rationale   | ADR             |
| -------- | ----------- | --------------- |
| ...      | Because ... | ADR-NNNN / None |

---

## 11. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | 🔴 High, 🟡 Medium, or 🟢 Low | ...    |

If none: _"No open questions at time of writing."_
```

---

## Feature Infrastructure Design Template

```markdown
# Infrastructure Design: {Short Feature Title}

**Feature ID:** F-NNNN
**Status:** Accepted
**Author:** devops-engineer
**Date:** YYYY-MM-DD
**Upstream:** docs/project/infrastructure-design.md, specs/technical-spec.md

---

## 1. Infra Impact Summary

List every infrastructure change this feature introduces.

| Change Type              | Description |
| ------------------------ | ----------- |
| New service / container  | ...         |
| New database / schema    | ...         |
| New secret / env var     | ...         |
| New external integration | ...         |
| Pipeline change          | ...         |

If none: _"This feature requires no infrastructure changes."_

---

## 2. New Deployment Units

For each new service or container introduced by this feature:

### {ServiceName}

**Deployment target:** ...
**Runtime:** ...
**Scaling:** ...
**Dependencies:** ...

---

## 3. Environment Variables and Secrets

| Name | Type            | Environment        | Secrets Manager Path | Injected Via |
| ---- | --------------- | ------------------ | -------------------- | ------------ |
| ...  | Secret / Config | dev, staging, prod | ...                  | ...          |

All secrets must follow the project's secrets management convention in
`docs/project/infrastructure-design.md`.

---

## 4. Pipeline Changes

List any changes required to the CI/CD pipeline defined in
`docs/project/infrastructure-design.md`.

- ...

If none: _"No pipeline changes required."_

---

## 5. Deployment Steps

Ordered steps to deploy this feature's infra changes.

1. ...
2. ...
3. ...

### Rollback Procedure

1. ...
2. ...

---

## 6. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | 🔴 High, 🟡 Medium, or 🟢 Low | ...    |

If none: _"No open questions at time of writing."_
```

---

## Writing Principles

- **Infra design defines decisions and conventions, not scripts.** This document
  specifies what Terraform modules to write, what pipeline stages to configure,
  and what secrets to create — not the IaC code itself. Implementation happens
  in the toolchain, not here.
- **Every service in system-architecture.md must have a deployment home.**
  If a service appears in the architecture and has no deployment target defined
  here, that is a gap — not an assumption.
- **Secrets never appear in plaintext.** If a secret value is mentioned anywhere
  in this document, that is a blocking error. Reference paths and injection methods
  only.
- **Rollback is not optional.** Every deployment change must have a defined
  rollback procedure. "Redeploy the previous version" is not a procedure —
  state the exact steps.
- **Environments are not just copies of prod at smaller scale.** Document
  meaningful behavioral differences — mocked external services, test data seeding,
  feature flag states — that affect how developers and agents use each environment.
