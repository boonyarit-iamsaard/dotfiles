#!/usr/bin/env python3
"""CLI tests for set-theme, run against a temporary home, state and checkout."""

from __future__ import annotations

import os
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("set-theme")
REPO_ROOT = Path(__file__).resolve().parent.parent
THEMES = ("catppuccin-macchiato", "catppuccin-mocha", "dark-2026", "default-dark-modern")


class SetThemeTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        fixture = Path(self.temporary.name).resolve()
        self.home = fixture / "home"
        self.state_home = fixture / "state"
        self.root = fixture / "dotfiles"
        self.home.mkdir()
        self.state = self.state_home / "dotfiles/theme"
        for name in ("catppuccin-macchiato", "dark-2026"):
            self.add_theme(name)
        # Stands in for the links check-links --create makes.
        (self.home / ".config").symlink_to(self.root / ".config")

    def add_theme(self, name: str, tools: tuple[str, ...] = ("starship", "lazygit")) -> None:
        files = {
            "starship": f".config/starship.{name}.toml",
            "lazygit": f".config/lazygit/themes/{name}.yml",
        }
        for tool in tools:
            path = self.root / files[tool]
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(f"{name}\n", encoding="utf-8")

    def run_theme(self, *args: str, root: Path | None = None, **env: str) -> subprocess.CompletedProcess[str]:
        environment = {**os.environ, "XDG_STATE_HOME": str(self.state_home), **env}
        return subprocess.run(
            [str(SCRIPT), "--home", str(self.home), "--root", str(root or self.root), *args],
            text=True,
            capture_output=True,
            env=environment,
        )

    def exports(self) -> dict[str, str]:
        result = self.run_theme("--env")
        self.assertEqual(result.returncode, 0, result.stderr)
        shell = subprocess.run(
            ["zsh", "-fc", f'{result.stdout}\nprint -r -- "$STARSHIP_CONFIG"; print -r -- "$LG_CONFIG_FILE"'],
            text=True,
            capture_output=True,
            check=True,
        )
        starship, lazygit = shell.stdout.splitlines()
        return {"STARSHIP_CONFIG": starship, "LG_CONFIG_FILE": lazygit}

    def test_named_switch_saves_the_theme_for_new_shells(self) -> None:
        result = self.run_theme("dark-2026")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.state.read_text(encoding="utf-8"), "dark-2026\n")
        self.assertEqual(
            self.exports(),
            {
                "STARSHIP_CONFIG": f"{self.home}/.config/starship.dark-2026.toml",
                "LG_CONFIG_FILE": f"{self.home}/.config/lazygit/config.yml,{self.home}/.config/lazygit/themes/dark-2026.yml",
            },
        )

    def test_bad_selections_are_refused_before_anything_is_saved(self) -> None:
        self.add_theme("half-done", tools=("starship",))
        for name, message in (
            ("../dark-2026", "not a theme name"),
            ("solarized", "Unknown theme 'solarized'"),
            ("half-done", "no file for: LazyGit"),
        ):
            with self.subTest(name=name):
                result = self.run_theme(name)
                self.assertEqual(result.returncode, 1)
                self.assertIn(message, result.stderr)
                self.assertFalse(self.state.exists())

    def test_list_shows_complete_themes_and_marks_the_active_one(self) -> None:
        self.add_theme("half-done", tools=("lazygit",))
        self.assertEqual(self.run_theme("--list").stdout, "* catppuccin-macchiato\n  dark-2026\n")

        self.run_theme("dark-2026")
        self.assertEqual(self.run_theme("--list").stdout, "  catppuccin-macchiato\n* dark-2026\n")

    def test_reapply_uses_the_default_without_saving_it(self) -> None:
        result = self.run_theme()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Applied theme catppuccin-macchiato", result.stdout)
        self.assertFalse(self.state.exists())
        self.assertEqual(self.exports()["STARSHIP_CONFIG"], f"{self.home}/.config/starship.catppuccin-macchiato.toml")

    def test_reapply_uses_the_saved_theme(self) -> None:
        self.run_theme("dark-2026")
        result = self.run_theme()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Applied theme dark-2026", result.stdout)

    def test_corrupt_state_blocks_reapply_but_a_name_recovers(self) -> None:
        self.state.parent.mkdir(parents=True)
        self.state.write_text("Dark 2026!\n", encoding="utf-8")

        reapply = self.run_theme()
        self.assertEqual(reapply.returncode, 1)
        self.assertIn("is not a theme name", reapply.stderr)

        recover = self.run_theme("dark-2026")
        self.assertEqual(recover.returncode, 0, recover.stderr)
        self.assertEqual(self.state.read_text(encoding="utf-8"), "dark-2026\n")

    def test_shell_startup_warns_and_uses_the_default_for_unusable_state(self) -> None:
        self.add_theme("half-done", tools=("lazygit",))
        self.state.parent.mkdir(parents=True)
        for saved in ("Dark 2026!", "solarized", "half-done"):
            with self.subTest(saved=saved):
                self.state.write_text(f"{saved}\n", encoding="utf-8")
                result = self.run_theme("--env")
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertIn("warning:", result.stderr)
                self.assertEqual(
                    self.exports()["STARSHIP_CONFIG"], f"{self.home}/.config/starship.catppuccin-macchiato.toml"
                )

    def test_check_passes_when_installed_files_and_shell_match(self) -> None:
        self.run_theme("dark-2026")

        result = self.run_theme("--check", **self.exports())

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("dark-2026", result.stdout)

    def test_check_reports_drift_without_repairing_it(self) -> None:
        exports = self.exports()
        self.run_theme("dark-2026")
        (self.home / ".config").unlink()

        result = self.run_theme("--check", **exports)

        self.assertEqual(result.returncode, 1)
        self.assertIn("starship theme file", result.stdout)
        self.assertIn("STARSHIP_CONFIG does not use active theme 'dark-2026'", result.stdout)
        self.assertIn("LG_CONFIG_FILE does not use active theme 'dark-2026'", result.stdout)
        self.assertFalse((self.home / ".config").exists())

    def test_check_reports_a_copy_that_is_not_the_checkout_file(self) -> None:
        self.run_theme("dark-2026")
        exports = self.exports()
        (self.home / ".config").unlink()
        stale = self.home / ".config/starship.dark-2026.toml"
        stale.parent.mkdir(parents=True)
        stale.write_text("old copy\n", encoding="utf-8")

        result = self.run_theme("--check", **exports)

        self.assertEqual(result.returncode, 1)
        self.assertIn(f"{stale} is not the checkout's file", result.stdout)

    def test_shell_startup_uses_the_default_when_the_theme_is_not_installed(self) -> None:
        self.run_theme("dark-2026")
        (self.home / ".config").unlink()

        result = self.run_theme("--env")

        self.assertIn("warning:", result.stderr)
        self.assertIn("starship.catppuccin-macchiato.toml", result.stdout)

    def test_shell_startup_warns_for_unreadable_state(self) -> None:
        self.state.parent.mkdir(parents=True)
        self.state.write_bytes(b"\xff\xfe\n")

        result = self.run_theme("--env")

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("warning:", result.stderr)
        self.assertNotIn("Traceback", result.stderr)
        self.assertIn("starship.catppuccin-macchiato.toml", result.stdout)

    def test_the_tracked_shell_config_names_no_theme(self) -> None:
        zshrc = (REPO_ROOT / ".zshrc").read_text(encoding="utf-8")
        for name in THEMES:
            self.assertNotIn(name, zshrc)
        self.assertNotRegex(zshrc, r"(?m)^export (STARSHIP_CONFIG|LG_CONFIG_FILE)=")

    def test_every_theme_is_complete_in_the_checkout(self) -> None:
        listed = self.run_theme("--list", root=REPO_ROOT).stdout.split()
        self.assertEqual([name for name in listed if name != "*"], list(THEMES))


if __name__ == "__main__":
    unittest.main()
