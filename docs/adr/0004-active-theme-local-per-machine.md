# Active theme chosen per machine, never committed

Each machine keeps its active theme in a local state file outside the
repository, and a platform's `set-theme` script applies it to every themed tool.
With no state file, the machine uses the default theme, Catppuccin Macchiato.
The repository holds every theme's files but never says which one is active. We
chose this because the active theme changes often (twice in two days in November
2026), and committing every switch filled `main` with commits that each touched
several files and the theme test.

## Considered Options

- **Active theme in tracked config (the earlier setup)**: rejected; every switch
  was a commit that hand-edited each tool's config and the theme test.
- **One tracked theme value per platform, spread by a script**: rejected; it
  cuts the commit down to one line, but switching is still a commit.
- **Gitignored state file inside the checkout**: rejected; a state file outside
  the repository can't be committed by accident, and it survives a re-clone.

## Consequences

Tools whose config is linked from the repository and can't read the state at
runtime get a generated copy instead of a link (LazyDocker on Windows). On
Windows, `set-theme` edits only the `colorScheme` value in Windows Terminal's
user-owned `settings.json`, a deliberate exception to the rule that scripts
never modify unmanaged user files. The theme check confirms that every theme has
a file for each tool, and the system check confirms that the installed configs
match the active theme. macOS and WSL keep their tracked active themes until
their own `set-theme` lands.
