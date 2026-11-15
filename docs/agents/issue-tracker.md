# Issue tracker: GitHub Issues

Issues and specs for this repo live in GitHub Issues on
`boonyarit-iamsaard/dotfiles`. Use the `gh` CLI; the repo is public, so every
issue, comment and label is public.

## Conventions

- A **spec** is a parent issue. Its tickets are **sub-issues** of it.
- One ticket per issue. The title is the ticket's name, with no number prefix;
  the issue number is the ticket number (`#7`, "ticket 7").
- Triage state is one label per open issue (see `triage-labels.md`). Done is a
  closed issue with reason `completed`; dropped is closed `not planned` with
  `wontfix`.
- Blocking is recorded twice: a `**Blocked by:** #N, #N` line in the body for
  readers, and a GitHub issue dependency for the tracker
  (`gh api -X POST repos/{owner}/{repo}/issues/{n}/dependencies/blocked_by -F issue_id=<blocker id>`,
  where the id is the blocker's `.id` from
  `gh api repos/{owner}/{repo}/issues/{n}`, not its number).
- Each ticket body keeps its `**Where:**` line: which machine may do the work.
- Checkboxes in the body track progress; tick them by editing the body. Outcomes
  and conversation go in issue comments.

## When a skill says "publish to the issue tracker"

`gh issue create --title ... --body-file ... --label <triage label>`. For a
ticket, add it as a sub-issue of its spec
(`gh api -X POST repos/{owner}/{repo}/issues/<spec>/sub_issues -F sub_issue_id=<ticket id>`)
and add its dependencies.

## When a skill says "fetch the relevant ticket"

`gh issue view <number> --comments`. The user will normally pass the number.

## Wayfinding operations

Used by `/wayfinder`. The **map** is a parent issue with one **child** sub-issue
per ticket.

- **Map**: the parent issue's body (the Notes / Decisions-so-far / Fog body).
- **Child ticket**: a sub-issue of the map, with the question in the body. A
  label records the ticket type (`research`/`prototype`/`grilling`/`task`);
  create the label if it is missing.
- **Blocking**: issue dependencies, as above. A ticket is unblocked when every
  issue blocking it is closed.
- **Frontier**: the map's open sub-issues that are unblocked and unassigned;
  lowest number wins.
- **Claim**: assign yourself (`gh issue edit <n> --add-assignee @me`) before any
  work.
- **Resolve**: comment the answer under an `## Answer` heading, close the issue,
  then append a context pointer (gist + link) to the map's Decisions-so-far by
  editing the map's body.
