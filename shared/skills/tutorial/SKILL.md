---
name: tutorial
description:
  Write a cited, step-by-step tutorial for a feature or task the human builds by
  hand, then coach them through it without writing their code.
disable-model-invocation: true
argument-hint: "What will you build by hand?"
---

# Tutorial

A **tutorial** is a Markdown document the human reads and works through to build
one real thing themselves: a feature, an endpoint, a config, a script. The human
writes every line of the project's code. You are the **coach**: you write the
tutorial, check each step, and give hints. The only files you write are the
tutorial and the learning workspace.

A tutorial teaches by **worked example, then exercise**. Each step shows the
pattern on a minimal example taken from the official docs. The human then
applies it to their own feature, where the code differs from the example, so
copying the example is never the answer.

Every step is **cited**: it links the official page that backs it, fetched in
this session. Recalled APIs go stale, so a step without a source fetched today
is a gap to research.

The skeleton and one worked step are in [template.md](template.md).

## Process

### 0. Setup

Read the `## Agent skills` block in the project's `CLAUDE.md` or `AGENTS.md`. If
it has a `### Tutorials` entry, take the workspace path and version-control
choice from it and skip to step 1.

Otherwise ask, one question at a time, leading with the recommendation:

1. **Workspace.** If a `/teach` workspace exists in the project (a `MISSION.md`
   or a `learning-records/` folder), recommend sharing it. Otherwise recommend
   `tutorials/` at the project root.
2. **Version control.** Commit the workspace, or add it to `.gitignore`.
   Recommend committing when the project is the human's own and gitignoring when
   it is shared with others.

Write the answers as a `### Tutorials` entry in the `## Agent skills` block,
creating the block if it is missing. The entry gives the path and the choice in
one line, for example
`Tutorials live in tutorials/ (committed). Run /tutorial to start one.` Apply
the `.gitignore` change if that was the choice.

**Done when:** the project's agent file holds the `### Tutorials` entry and the
workspace folder exists.

### 1. Scope

Input is an issue or spec, or a free-text goal. From a file, read it and
everything it links. From free text, restate the goal and a "done when" list,
and confirm it with the human.

Read what the human already knows: `MISSION.md`, `learning-records/` and
`NOTES.md` in the workspace, when they exist. Ask what they know of the language
or tool when the records say nothing. Skip what a record shows they have
mastered, and spend steps on what is new.

Find the **oracle**: the command that proves the feature works, such as a test
suite, a contract test, a build, or a request with an expected response. When
the project has none, the first step of the tutorial builds one with the human.

Read the existing code the feature touches, or the code it ports. Port its
behaviour, not its syntax.

**Done when:** you hold an ordered list of outcomes, each traceable to a "done
when" item, and the oracle is named.

### 2. Research

Research inline, so the docs stay in context for the coaching:

1. context7 for language, framework and library references.
2. WebFetch on the official docs domain for guides and idioms.
3. WebSearch only to locate an official page. Cite the page, never the search.

For each outcome, record the page URL, the idiomatic way the docs recommend, and
the trap they warn about.

**Done when:** every outcome maps to at least one official page fetched in this
session.

### 3. Decisions

The docs often fork: two libraries, two project layouts, a newer and an older
API. Put each fork to the human with a recommendation, and wait. Record the
answers in the tutorial's Decisions section. A fork the human chooses teaches
more than one you settle.

**Done when:** no step depends on an option the human has not chosen.

### 4. Write

Copy [template.md](template.md) into the workspace as
`NNNN-<dash-case-name>.md`, numbered after the highest existing tutorial. Fill
it:

- **One concept per step.** A step adds one idea and ends on an Expect the human
  can observe. Split a larger step into `3a`, `3b`.
- **Order** the steps so the oracle goes green as early as possible, then stays
  green as the steps add behaviour: a walking skeleton first, then one slice at
  a time.
- **Exercise, not solution.** The Exercise names what to build in the human's
  project and the constraint it must meet. Its code lives in the hints, revealed
  only on request.
- **Recall** at the end: two or three questions the human answers from memory,
  covering this tutorial and one earlier one when a record exists.

**Done when:** every outcome from step 1 is covered by a step, and each step has
a cited worked example, an exercise and an Expect.

### 5. Review gate

Stop. Give the human the tutorial's path and ask them to read it. Coaching
starts only when they say to begin. If they edited the file, re-read it first.

### 6. Coach

Present one step per message. When the human reports a step done:

- Run the step's **Check**: the oracle, a build, or reading their diff. On a
  pass, tick the step. On a fail, show what failed and climb the **hint ladder**
  one rung per request: the concept involved, then where to look in the docs,
  then the shape of the code, then the code for that one line. The human types
  the fix.
- Review their code against the idiom the cited docs recommend. Name a
  difference and why it matters, and let them change it.
- Answer every question, and cite the docs when the answer is a fact.
- When the docs differ from what the human sees, re-fetch the cited page,
  correct the step, and log it in the Run log.

When a step shows genuine understanding, corrects a misconception, or the human
discloses prior knowledge, write a learning record in the workspace's
`learning-records/`, numbered and formatted like `/teach`'s records: the title,
then one to three sentences on what is known now and what it changes.

**Resuming** in a new session: read the tutorial and start at the first unticked
step. If the "Docs checked" date is more than 30 days old, re-fetch the sources
of the remaining steps first and log what changed.

**Done when:** every step is ticked, the oracle is green, the human has answered
the Recall questions, and the Run log records the session.
