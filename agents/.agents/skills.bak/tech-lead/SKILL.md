---
name: tech-lead
description: "Produce a technical specification for a feature OR a system-wide architecture document for a project. Use this skill when the user says 'write the technical spec', 'design the solution', 'tech lead phase', or hands off a feature for technical design. Also triggers for project-level requests like 'write the system architecture', 'project architecture phase', 'design the system', or 'tech lead the project' — in which case this skill runs in Project Mode and produces system-architecture.md. Reads upstream artifacts (requirements.md for features, project-requirements-document.md for projects) and any existing ADRs. Flags non-obvious decisions for ADR authoring before committing to a design. Always invoke this skill after the product-owner skill has accepted a feature or project, and before the devops-engineer or senior-developer skill runs."
---

# Tech Lead Skill

Translate accepted requirements into a concrete, unambiguous technical specification
or system-wide architecture that downstream agents can consume without making design
decisions. Every choice in this document should be deliberate — if a choice cannot be
justified by the requirements or existing ADRs, it either warrants an ADR or should be
flagged as an open question.

This skill has two modes. Identify which applies before proceeding.

**Feature Mode** — Produces `technical-spec.md` for a single feature.
Triggered when a feature (F-NNNN) is being handed off for technical design.

**Project Mode** — Produces `system-architecture.md` for the full system.
Triggered when the user says "project architecture", "system design", "tech lead the project",
or when no feature ID is referenced and a project-level design is needed.

---

## Feature Mode

### F-Step 1 — Read the Feature Package

Before doing anything else, read in this order:

1. `docs/features/{F-NNNN}-{slug}/README.md` — confirm PO phase is `✅ Accepted`
2. `docs/features/{F-NNNN}-{slug}/specs/requirements.md` — full requirements, constraints, non-goals
3. `docs/features/{F-NNNN}-{slug}/adr/` — any existing ADRs for this feature
4. `docs/project/system-architecture.md` — if it exists, read it. Feature decisions must not contradict it.

If PO phase is not `✅ Accepted`, stop and inform the user. Do not proceed.

---

### F-Step 2 — Identify ADR Trigger Points

Before designing anything, scan the requirements for decisions that cannot justify
themselves from the requirements alone. Use this heuristic:

| Signal                                                         | Action                            |
| -------------------------------------------------------------- | --------------------------------- |
| Multiple viable approaches exist with non-obvious tradeoffs    | Flag for ADR                      |
| New technology, library, or pattern not established in project | Flag for ADR                      |
| Decision has significant long-term architectural consequences  | Flag for ADR                      |
| One approach is clearly correct given constraints              | Decide inline, document rationale |
| User explicitly requests an ADR for this decision              | Flag for ADR                      |

If ADR triggers are found:

- List them explicitly to the user before writing the spec
- Pause spec writing at those sections
- Indicate which sections are blocked pending ADR resolution
- Resume and complete the spec once ADRs are accepted

If no ADR triggers are found, proceed directly to spec writing.

---

### F-Step 3 — Write technical-spec.md

Write to `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md`.

Follow the **Technical Spec Template** section below exactly.

---

### F-Step 4 — Update README.md

Append a row to the Decision Log:

```
| YYYY-MM-DD | Tech Lead phase accepted | technical-spec.md written |
```

Update the Phase Tracker:

- `Tech Lead` → `✅ Accepted`
- `ADR` → `✅ Accepted` / `⚪ Optional` / `❌ Skipped` based on outcome of F-Step 2
- Update `technical-spec.md` row in Artifact Index to `✅ Accepted`

---

### F-Step 5 — Self-Check Before Presenting

- [ ] Every user story in requirements.md is addressed by at least one component or endpoint
- [ ] All API endpoints include request/response shapes — no "TBD" fields
- [ ] All data model fields include type and nullability
- [ ] Non-goals from requirements.md are not implemented anywhere in the spec
- [ ] Every inline design decision includes a brief rationale
- [ ] ADR trigger points were resolved before spec was finalized
- [ ] No decisions contradict system-architecture.md (if it exists)
- [ ] No decisions left implicit — if uncertain, it is in Open Questions

---

### F-Step 6 — Save and Present

Output paths:

- `docs/features/{F-NNNN}-{slug}/specs/technical-spec.md` (new)
- `docs/features/{F-NNNN}-{slug}/README.md` (updated)

---

## Project Mode

### P-Step 1 — Read the Project Package

Before doing anything else, read in this order:

1. `docs/project/project-requirements-document.md` — confirm it exists and status is `Accepted`
2. `docs/adr/` — any existing project-level ADRs
3. Any other project-level context the user provides

If `project-requirements-document.md` does not exist, stop and inform the user.
The product-owner must complete Project Mode before this skill can proceed.

---

### P-Step 2 — Identify ADR Trigger Points

Scan the PRD for decisions that require explicit evaluation before committing to architecture:

| Signal                                                   | Action                                  |
| -------------------------------------------------------- | --------------------------------------- |
| Multiple viable stack choices with non-obvious tradeoffs | Flag for ADR                            |
| New technology or platform not previously used by team   | Flag for ADR                            |
| Data storage strategy (DB type, sharding, multi-tenancy) | Flag for ADR if non-obvious             |
| Auth and identity architecture                           | Flag for ADR if non-trivial             |
| Service communication pattern (REST, gRPC, messaging)    | Flag for ADR if multiple viable options |
| Decision clearly mandated by constraints in PRD          | Decide inline, document rationale       |

List all ADR triggers to the user and resolve them before finalizing the architecture.

---

### P-Step 3 — Write system-architecture.md

Write to `docs/project/system-architecture.md`.

Follow the **System Architecture Template** section below exactly.

Scope: **decisions and conventions only**. This document defines what is built and how
components relate. It does not include deployment pipeline configuration, IaC scripts,
or environment-specific settings — those belong to `infrastructure-design.md` (devops-engineer).

---

### P-Step 4 — Self-Check Before Presenting

- [ ] Every epic in project-requirements-document.md is addressed by at least one service or component
- [ ] Stack decisions are justified — not just stated
- [ ] Database design covers entity groupings, not just technology choice
- [ ] Cross-cutting concerns (auth, logging, error handling) are defined — not deferred
- [ ] Non-functional requirements from PRD are addressed in the architecture
- [ ] Out-of-scope items from PRD do not appear in the architecture
- [ ] ADR trigger points were resolved before architecture was finalized
- [ ] No decisions left implicit — if uncertain, it is in Open Questions

---

### P-Step 5 — Save and Present

Output path:

- `docs/project/system-architecture.md`

---

## Technical Spec Template

````markdown
# Technical Spec: {Short Feature Title}

**Feature ID:** F-NNNN
**Status:** Accepted
**Author:** tech-lead
**Date:** YYYY-MM-DD
**Depends On:** [ADR-NNNN if applicable, or "No ADRs required"]

---

## 1. Overview

2–3 paragraphs. Summarize the technical approach at a high level.
Answer: _"How is this being built, and why this way?"_
Reference requirements.md US-XXX story IDs where relevant.

---

## 2. Architecture

Describe how this feature fits into the existing system.
Use Mermaid diagrams for component topology and data flow. Fall back to ASCII only
when the diagram is a simple inline snippet or Mermaid cannot express it clearly.

```mermaid
graph LR
    Client --> API
    API --> Service
    Service --> Repository
    Repository --> DB
    API --> ExternalAPI
```
````

Keep diagrams focused on this feature's boundaries. Do not redraw the entire system.

---

## 3. Components

List every new or modified component. For each, state its responsibility and
its interface contract with other components.

### {ComponentName}

**Type:** Service / Controller / Repository / Hook / Component / etc.
**Responsibility:** One sentence.
**Location:** `src/{path/to/component}`

**Interface:**

- Input: ...
- Output: ...
- Side effects: ...

---

## 4. API Contracts

Document every endpoint this feature exposes or consumes.

### {HTTP Method} {/path}

**Purpose:** One sentence.
**Auth required:** Yes / No

**Request:**
\```json
{
"field": "type — description"
}
\```

**Response 200:**
\```json
{
"field": "type — description"
}
\```

**Error responses:**
| Status | Condition |
|---|---|
| 400 | ... |
| 404 | ... |
| 500 | ... |

---

## 5. Data Models

Document every new or modified entity, table, or schema.

### {ModelName}

| Field | Type | Nullable | Description |
| ----- | ---- | -------- | ----------- |
| id    | UUID | No       | Primary key |
| ...   | ...  | ...      | ...         |

**Indexes:** ...
**Constraints:** ...

---

## 6. Key Design Decisions

Document every non-obvious inline decision made in this spec.
This is not an ADR — it is a record of deliberate choices that did not
rise to the level of requiring one. Each entry must include a rationale.

| Decision | Rationale   |
| -------- | ----------- |
| ...      | Because ... |

If all decisions are covered by ADRs: _"All design decisions documented in ADR(s) listed above."_

---

## 7. Implementation Notes

Guidance for the developer agent. Ordered by implementation sequence.

1. ...
2. ...
3. ...

Include:

- File creation order if there are dependencies between files
- Known edge cases to handle explicitly
- Error handling expectations
- Any patterns already established in the codebase to follow

---

## 8. Out of Scope

Restate the non-goals from requirements.md. This section exists so the developer
agent does not need to cross-reference requirements.md for boundary decisions.

- ...

---

## 9. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | 🔴 High, 🟡 Medium, or 🟢 Low | ...    |

If none: _"No open questions at time of writing."_

`````

---

## System Architecture Template

````markdown
# System Architecture

**Project:** {Project Name}
**Status:** Accepted
**Author:** tech-lead
**Date:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD
**Depends On:** [ADR-NNNN list, or "No ADRs required"]
**Upstream:** docs/project/project-requirements-document.md

---

## 1. Overview

2–3 paragraphs. Summarize the architectural approach at a high level.
Answer: _"What are we building, how is it structured, and why?"_
Reference epics from project-requirements-document.md where relevant.

---

## 2. Technology Stack

| Layer | Technology | Rationale |
|---|---|---|
| Frontend | ... | ... |
| Backend | ... | ... |
| Database | ... | ... |
| Auth | ... | ... |
| Messaging / Async | ... | ... |
| Caching | ... | ... |
| Search | ... | ... |

Document only layers relevant to this system. Omit layers not in scope.

---

## 3. System Context

High-level diagram showing the system and its external dependencies.
Use Mermaid for all diagrams.

```mermaid
graph TB
    User --> System
    System --> ExternalAPI
    System --> DB
    System --> Auth
```

---

## 4. Service / Component Boundaries

List every service, module, or major component. For each, state its single
responsibility and what it owns exclusively.

### {ServiceName}

**Responsibility:** One sentence.
**Owns:** What data, domain logic, or capability belongs exclusively to this service.
**Exposes:** APIs, events, or interfaces consumed by other services.
**Depends On:** Other services or external systems this service calls.

---

## 5. Data Architecture

### Database Design

Describe entity groupings and which service owns each domain.
Do not define full schemas here — that belongs in feature technical-spec.md files.

| Domain / Aggregate | Owner Service | Storage | Notes |
| ------------------ | ------------- | ------- | ----- |
| ...                | ...           | ...     | ...   |

### Data Conventions

- Primary key strategy: ...
- Audit fields (createdAt, updatedAt): ...
- Soft delete vs. hard delete: ...
- Multi-tenancy approach (if applicable): ...

---

## 6. Cross-Cutting Concerns

### Authentication and Authorization

- Auth mechanism: ...
- Token strategy: ...
- Authorization model (RBAC, ABAC, etc.): ...
- Service-to-service auth: ...

### API Design Conventions

- Protocol: REST / gRPC / GraphQL
- Versioning strategy: ...
- Error response shape: ...
- Pagination convention: ...

### Logging and Observability

- Logging standard: ...
- Correlation ID strategy: ...
- Metrics collection: ...
- Alerting approach: ...

### Error Handling

- Error propagation strategy across service boundaries: ...
- Retry and circuit-breaker approach: ...

---

## 7. Key Architecture Decisions

Document every non-obvious inline decision made in this document.
Decisions that required deeper evaluation should have their own ADR referenced here.

| Decision | Rationale   | ADR             |
| -------- | ----------- | --------------- |
| ...      | Because ... | ADR-NNNN / None |

---

## 8. Out of Scope

Architectural areas explicitly not addressed in this document.
These are not rejected — they are deferred or owned elsewhere.

- Deployment pipeline configuration → infrastructure-design.md (devops-engineer)
- IaC scripts and environment-specific config → infrastructure-design.md (devops-engineer)
- Feature-level data models and API contracts → individual technical-spec.md files
- ...

---

## 9. Open Questions

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | 🔴 High, 🟡 Medium, or 🟢 Low | ...    |

If none: _"No open questions at time of writing."_

`````

---

## Writing Principles

- **Every decision must be justified.** A developer agent reading this spec should
  never have to make a design choice. If a choice is not obvious, explain it.
  If it cannot be explained without deeper analysis, it needs an ADR.
- **Specs reference requirements, not the other way around.** Cite US-XXX IDs
  when a component or endpoint directly addresses a user story.
- **Non-goals are a hard boundary.** If it appears in requirements.md non-goals,
  it must not appear anywhere in this spec. Flag any conflict immediately.
- **Implementation Notes are for the developer agent, not the architect.**
  Write them as concrete, sequenced steps — not high-level guidance.
- **No TBD fields in API contracts or data models.** If a field is unknown,
  it belongs in Open Questions with a blocking flag, not left implicit in the spec.
- **System architecture defines decisions, not implementations.** CI/CD pipeline
  config, IaC, and environment details belong in infrastructure-design.md.
  If in doubt whether something belongs here or there — if it's a convention or
  decision, it goes here; if it's a config or script, it goes to devops-engineer.
