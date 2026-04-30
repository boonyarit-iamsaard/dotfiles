---
name: adr-author
description: Create Architecture Decision Records (ADRs) as well-structured Markdown files following the MADR convention. Trigger on phrases like "document this decision", "write up our architecture choices", "turn this into an ADR", or "we decided to use X over Y".
---

# ADR Skill

Produce a complete, well-structured Architecture Decision Record (ADR) as a Markdown file
ready to be committed to a repository under `docs/adr/`.

ADRs are permanent engineering artifacts. They exist to answer the question a future developer
will ask: _"Why was this built this way?"_ — not just what was decided, but what was considered,
what was rejected, and what tradeoffs were accepted. Write with that developer in mind.

---

## Workflow

### Step 1 — Extract Context From the Conversation

Before asking the user anything, mine the current conversation for:

- The decision being made and the problem it solves
- Options that were considered (including rejected ones)
- Constraints that shaped the decision
- Rationale given for the final choice
- Any consequences, risks, or tradeoffs acknowledged
- Open questions that remain unresolved

The goal is to arrive at the interview with as much pre-filled as possible. Do not ask the
user to repeat what they have already said.

---

### Step 2 — Fill Gaps With Targeted Questions

Ask only for what the conversation does not already answer. Common gaps:

- ADR number (if a sequence already exists in the repo)
- Author and reviewer names
- Status — is this `Draft`, `Accepted`, or `Supersedes` a prior ADR?
- Staff role definitions or other domain-specific open questions that affect the decision

Keep this to the minimum necessary. One focused question is better than a list of five.

---

### Step 3 — Write the ADR

Produce the file using the structure in the **ADR Template** section below.

**File naming convention:**

```
docs/adr/NNNN-kebab-title.md
```

Use a four-digit zero-padded prefix (`0001`, `0002`, etc.) following the MADR convention.
If the user has not specified a number, ask or infer from context.

**Writing principles:**

- Use the imperative mood for decisions: _"Use OpenIddict"_, not _"We decided to use OpenIddict"_
- Document rejected options with honest rationale — this is the most valuable part of an ADR
- Keep consequences explicit: both positive outcomes and accepted tradeoffs
- Never omit the Options Considered section — future developers need to know what was evaluated
- Open questions belong in the ADR, not left implicit — flag them with owner and priority
- Write for a mid-level developer who is unfamiliar with the project history

---

### Step 4 — Update Feature README.md

If this ADR was written as part of a feature workflow (i.e. a `docs/features/{F-NNNN}-*/README.md`
exists), update it after the ADR is accepted:

Append a row to the Decision Log:

```
| YYYY-MM-DD | ADR-NNNN accepted | {one-line summary of the decision} |
```

Update the Phase Tracker:

- `ADR` → `✅ Accepted`

Update the Artifact Index — add a row for this ADR:

```
| ADR-NNNN-{slug}.md | ✅ Accepted | adr/NNNN-{slug}.md |
```

If no feature README exists (standalone ADR), skip this step.

---

### Step 5 — Save and Present

Save to `/mnt/user-data/outputs/docs/adr/NNNN-title.md` and present the file to the user
using the `present_files` tool.

---

## ADR Template

Use this exact structure. Do not omit sections — if a section has no content, note it
explicitly (e.g., _"No bundled resources required."_).

```markdown
# ADR-NNNN: [Short Title — Noun Phrase]

**Status:** [Draft | Accepted | Deprecated | Superseded by ADR-NNNN]
**Date:** YYYY-MM-DD
**Last Updated:** YYYY-MM-DD
**Author:** [Name or TBD]
**Reviewers:** [Names or TBD]

---

## Table of Contents

1. Context
2. Scope
3. Constraints
4. Options Considered
5. Decision
6. Architecture / Design ← rename to fit the domain
7. Detail Sections ← domain-specific content
8. Consequences
9. Open Questions
10. Decision Log

---

## 1. Context

Explain the situation that made this decision necessary. Describe the system, the problem,
and why a deliberate architectural choice was required. Write 2–4 paragraphs. This section
answers: _"What problem were we solving, and why did it matter?"_

---

## 2. Scope

List what this ADR covers and explicitly what it does not cover. Use two sub-lists:

**In scope:**

- ...

**Out of scope (addressed elsewhere or deferred):**

- ...

---

## 3. Constraints

List the non-negotiable constraints that bounded the decision space. These are the rules
the decision had to operate within — not preferences or tradeoffs.

- ...

---

## 4. Options Considered

Document every option that received serious consideration, including rejected ones.
Each option should include an honest assessment of its strengths, weaknesses, and
the reason it was accepted or rejected.

### Option A — [Name] [✅ Selected | ❌ Rejected]

Brief description.

| Aspect      | Assessment   |
| ----------- | ------------ |
| [Criterion] | [Assessment] |

Reason selected / rejected: ...

### Option B — [Name] [✅ Selected | ❌ Rejected]

...

---

## 5. Decision

State the decision in one or two sentences using the imperative mood.

> Use [X] for [purpose] because [primary reason].

If multiple sub-decisions were made, list them clearly.

---

## 6. Architecture / Design

Provide diagrams, stack tables, flow descriptions, or whatever visual/structural aids
make the decision concrete and understandable. Use Mermaid diagrams for topology and
flow visualization. Fall back to ASCII only for simple inline snippets or when Mermaid
cannot express the structure clearly.
Use tables for technology stacks and client/service registrations.

---

## [Domain-Specific Sections]

Add sections as needed for the specific domain of the ADR. Examples:

- Identity model and flows (auth ADRs)
- Data models (persistence ADRs)
- API contracts (service design ADRs)
- Migration strategy (database ADRs)
- Security constraints (security ADRs)

Keep each section focused. A section should answer one specific question a future
developer would have about the decision.

---

## N. Consequences

Be explicit. Split into two sub-sections.

### Positive

- ...

### Negative / Tradeoffs Accepted

- ...

---

## N. Open Questions

Use a table. Include owner and priority for each item.

| #   | Question | Owner | Priority                      | Blocks |
| --- | -------- | ----- | ----------------------------- | ------ |
| 1   | ...      | ...   | 🔴 High, 🟡 Medium, or 🟢 Low | ...    |

If there are no open questions, write: _"No open questions at time of writing."_

---

## N. Decision Log

Chronological record of every decision made during the ADR's lifetime, including
rejected alternatives. This is the audit trail — never delete entries.

| Date       | Decision | Rationale |
| ---------- | -------- | --------- |
| YYYY-MM-DD | ...      | ...       |
```

---

## Section Writing Guide

### Context

Answer: _why does this decision exist?_ Describe the system briefly, the problem it faces,
and what would happen without a deliberate decision here. Avoid implementation detail —
that belongs in later sections.

### Constraints

These are hard limits — things that were non-negotiable before options were evaluated.
If something was a preference rather than a constraint, it belongs in the options assessment,
not here.

### Options Considered

This is the most valuable section for future maintainers. A future developer inheriting
the system needs to know not just what was chosen, but what was evaluated and why it
was not chosen. Omitting rejected options means the next developer may revisit those
options without the benefit of prior analysis.

For each option include:

- A concise description
- An assessment table covering the criteria that mattered for this decision
- An explicit rejection or acceptance rationale

### Decision

One clear statement. Use the imperative: _"Use X"_, not _"We will use X"_ or _"It was
decided to use X"_. If the decision is conditional or deferred, say so explicitly.

### Consequences

Do not only list positive consequences. An ADR that only says why something was good
is not trustworthy — it reads like justification rather than analysis. List the
tradeoffs that were accepted. This helps future developers understand what the
original author knew they were giving up.

### Decision Log

Record every decision that was made during the ADR lifecycle, including:

- The initial technology or approach selections
- Rejected alternatives (with date and rationale)
- Deferred decisions (with the reason for deferral)
- Any updates or reversals after initial writing

---

## File Naming Reference

| Scenario                    | File name                                                                    |
| --------------------------- | ---------------------------------------------------------------------------- |
| First ADR in the repo       | `docs/adr/0001-title.md`                                                     |
| Subsequent ADRs             | `docs/adr/0002-title.md`, `0003-...`, etc.                                   |
| Superseding an existing ADR | New file with new number; update old file status to `Superseded by ADR-NNNN` |

Title should be a concise kebab-case noun phrase describing the subject of the decision,
not the outcome. Prefer `authentication-and-identity` over `use-openiddict`.

---

## Example — Completed ADR Fragment

The following shows how the Options Considered and Decision sections should read for
a technology selection decision. Notice that rejected options include honest rationale,
not just a dismissal.

```markdown
## 4. Options Considered

### Option A — ASP.NET Core Identity + OpenIddict ✅ Selected

Full OAuth 2.1 / OIDC compliant authorization server. Code-first, MIT licensed,
self-hosted — no MAU pricing, no vendor dependency. Supports Google and LINE
federation natively.

| Aspect             | Assessment                                                        |
| ------------------ | ----------------------------------------------------------------- |
| Vendor dependency  | None — fully self-hosted                                          |
| LINE Login support | Native via external IdP federation                                |
| Maintainability    | High — explicit code-first config, readable by any .NET developer |
| Operational burden | Medium — team owns key rotation and token store                   |

Selected because it satisfies all hard constraints with no external dependency.

### Option B — Auth0 ❌ Rejected

Managed identity provider. Free tier supports 25,000 MAU — sufficient for this scale.
However, LINE Login requires an enterprise connection (paid plan), and the custom
email capture flow for LINE users without an email address requires Auth0 Actions,
a proprietary runtime.

| Aspect                 | Assessment                                           |
| ---------------------- | ---------------------------------------------------- |
| LINE Login (free tier) | ❌ Not supported — enterprise plan required          |
| Custom flows           | Proprietary Actions runtime — increases handoff risk |
| MAU cost at scale      | Low risk for this property size                      |
| Vendor dependency      | High — pricing and feature set outside team control  |

Rejected due to LINE enterprise plan requirement and proprietary customization constraints.

## 5. Decision

Use ASP.NET Core Identity with OpenIddict as a self-hosted combined Authorization Server
and Resource Server, deployed as a .NET monolith.
```

---

## Quality Checklist

Before presenting the file, verify:

- [ ] Every rejected option has an explicit rationale — not just "not selected"
- [ ] Constraints section contains only hard limits, not preferences
- [ ] Consequences section includes both positives and accepted tradeoffs
- [ ] Open questions table includes owner and priority for each item
- [ ] Decision Log contains all decisions made, including deferred ones
- [ ] File is saved to `docs/adr/NNNN-title.md` using four-digit prefix
- [ ] Status field is set — Draft, Accepted, or Superseded
- [ ] ASCII diagrams or tables are present where topology or stack needs visualization
