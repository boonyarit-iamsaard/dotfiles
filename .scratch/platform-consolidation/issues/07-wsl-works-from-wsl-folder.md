# 07: WSL works from `wsl/`

**What to build:** The WSL machine runs from the integration branch. Its
checkout moves from `wsl` to the integration branch, the paths its scripts and
Stow packages assume are fixed for `wsl/`, its packages are restowed, and
everything keeps working. Repo-wide docs that came from WSL (`GLOSSARY.md`,
`docs/adr/`, `.markdownlint.json`) move to the root, and the root guides list
`wsl/`.

**Blocked by:** 06

**Where:** WSL machine only.

**Status:** ready-for-agent

- [ ] The checkout is on the integration branch with no local-only commits lost
- [ ] Restow from `wsl/` succeeds with no conflicts; no link points to a vanished path
- [ ] WSL's Python tests pass from `wsl/`
- [ ] Glossary, ADRs and markdownlint config live at the root; links to them still work
- [ ] The root README and agent guide list `wsl/` as live
- [ ] Pushed to the integration branch
