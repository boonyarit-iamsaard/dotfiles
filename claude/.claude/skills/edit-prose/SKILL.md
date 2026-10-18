---
name: edit-prose
description: Prose edit that strips AI writing tells while keeping the writer's voice. Use when tightening, editing, or reviewing prose - articles, docs, READMEs, PR text.
---

Edit prose with the rules in [rules.md](rules.md), adjusted by the house rules
below. Where the two conflict, the house rules win. `rules.md` is an upstream
file: its name, frontmatter and heading describe that project, not this skill.

## Steps

1. When the text is the user's own writing, read one or two of their published
   articles (`~/workspace/personal/foundry/content/articles/*/index.mdx`) as the
   voice sample. Their voice is short, plain sentences with dry first-person
   asides. Done when you can name what the sample does that the generic rules
   would flatten.
2. Read `rules.md` in full and edit with it and the house rules. Done when every
   pattern and every house rule has been checked against the whole text.

## House rules

- **Spelling** - US English (`color`, `center`, `-ize`), including on lines you
  otherwise leave untouched.
- **Voice** - personal asides, specific details and real uncertainty are the
  voice: keep them. Bold lead-ins that work as parallel subheads are a judgment
  call; keep them where they help a reader scan.
- **Facts as given** - every fact, name and date in the output is in the input.
  A sentence that hides its actor keeps that shape unless the text names the
  actor elsewhere.
- **Update sections** - a dated "Update" section is a change log: leave its
  wording as written. Move a later "updated" date only for substantive content
  changes; a wording edit leaves it where it is.
- **Naming the work** - branches, commits and PR text describe the edit itself:
  `tighten`, `edit`, `clarify`. Keep "humanize" out of them, along with any
  suggestion that the original text was AI-written.
