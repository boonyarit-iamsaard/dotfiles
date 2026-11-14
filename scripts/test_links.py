#!/usr/bin/env python3
"""CLI integration tests for the macOS link check."""

from __future__ import annotations

import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("links.py")


class LinksTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        fixture = Path(self.temporary.name).resolve()
        self.home = fixture / "home"
        self.root = fixture / "dotfiles"
        self.home.mkdir()
        self.root.mkdir()
        self.list_file = self.root / "links.tsv"

    def make_source(self, relative: str) -> Path:
        source = self.root / relative
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_text("fixture\n", encoding="utf-8")
        return source

    def declare(self, *entries: tuple[str, str]) -> None:
        lines = ["# target\tsource"]
        lines += [f"{target}\t{source}" for target, source in entries]
        self.list_file.write_text("\n".join(lines) + "\n", encoding="utf-8")

    def link(self, target: str, source: Path) -> Path:
        path = self.home / target
        path.parent.mkdir(parents=True, exist_ok=True)
        path.symlink_to(os.path.relpath(source, path.parent))
        return path

    def run_check(self, *args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--home",
                str(self.home),
                "--root",
                str(self.root),
                *args,
            ],
            text=True,
            capture_output=True,
        )

    def test_declared_links_that_resolve_pass(self) -> None:
        source = self.make_source(".config/tool/config")
        self.declare((".config/tool/config", ".config/tool/config"))
        self.link(".config/tool/config", source)

        result = self.run_check()

        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("links: 1 ok", result.stdout)

    def test_missing_declared_link_fails(self) -> None:
        self.make_source(".zshrc")
        self.declare((".zshrc", ".zshrc"))

        result = self.run_check()

        self.assertEqual(result.returncode, 1)
        self.assertIn("missing: .zshrc", result.stdout)

    def test_link_to_another_source_fails(self) -> None:
        self.make_source(".tmux.conf")
        other = self.make_source(".tmux.dracula.conf")
        self.declare((".tmux.conf", ".tmux.conf"))
        self.link(".tmux.conf", other)

        result = self.run_check()

        self.assertEqual(result.returncode, 1)
        self.assertIn("wrong: .tmux.conf -> .tmux.dracula.conf", result.stdout)

    def test_real_file_in_place_of_link_fails(self) -> None:
        self.make_source(".zshrc")
        self.declare((".zshrc", ".zshrc"))
        (self.home / ".zshrc").write_text("local\n", encoding="utf-8")

        result = self.run_check()

        self.assertEqual(result.returncode, 1)
        self.assertIn("not-a-link: .zshrc", result.stdout)

    def test_declared_source_missing_from_checkout_fails(self) -> None:
        self.declare((".zshenv", ".zshenv"))
        self.link(".zshenv", self.root / ".zshenv")

        result = self.run_check()

        self.assertEqual(result.returncode, 1)
        self.assertIn("no-source: .zshenv", result.stdout)

    def test_unlisted_link_into_checkout_fails(self) -> None:
        declared = self.make_source(".config/ghostty/themes/nord")
        theme = self.make_source(".config/ghostty/themes/dracula")
        self.declare((".config/ghostty/themes/nord", ".config/ghostty/themes/nord"))
        self.link(".config/ghostty/themes/nord", declared)
        self.link(".config/ghostty/themes/dracula", theme)
        self.link(".zshenv", self.root / "deleted.toml")

        result = self.run_check()

        self.assertEqual(result.returncode, 1)
        self.assertIn(
            "unlisted: .config/ghostty/themes/dracula -> "
            ".config/ghostty/themes/dracula",
            result.stdout,
        )
        self.assertIn("unlisted: .zshenv -> deleted.toml", result.stdout)

    def test_stow_owned_and_outside_links_are_ignored(self) -> None:
        declared = self.make_source(".claude/keybindings.json")
        statusline = self.make_source("claude/.claude/statusline.sh")
        self.declare((".claude/keybindings.json", ".claude/keybindings.json"))
        self.link(".claude/keybindings.json", declared)
        self.link(".claude/statusline.sh", statusline)
        self.link(".gitconfig", self.home / "elsewhere")

        result = self.run_check()

        self.assertEqual(result.returncode, 0, result.stdout)

    def test_create_adds_missing_links_as_relative_links(self) -> None:
        self.make_source("Library/Application Support/lazygit/config.yml")
        self.declare(
            ("Library/Application Support/lazygit", "Library/Application Support/lazygit")
        )

        result = self.run_check("--create")

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("created: Library/Application Support/lazygit", result.stdout)
        link = self.home / "Library" / "Application Support" / "lazygit"
        self.assertEqual(
            os.readlink(link), "../../../dotfiles/Library/Application Support/lazygit"
        )
        self.assertEqual(self.run_check().returncode, 0)

    def test_create_never_replaces_existing_files_or_links(self) -> None:
        self.make_source(".zshrc")
        other = self.make_source(".tmux.dracula.conf")
        self.make_source(".tmux.conf")
        self.declare((".zshrc", ".zshrc"), (".tmux.conf", ".tmux.conf"))
        (self.home / ".zshrc").write_text("local\n", encoding="utf-8")
        self.link(".tmux.conf", other)

        result = self.run_check("--create")

        self.assertEqual(result.returncode, 1)
        self.assertEqual((self.home / ".zshrc").read_text(encoding="utf-8"), "local\n")
        self.assertIn("wrong: .tmux.conf -> .tmux.dracula.conf", result.stdout)

    def test_malformed_list_is_rejected_with_its_line(self) -> None:
        for bad in (".zshrc .zshrc", "../escape\t.zshrc", ".zshrc\t.zshrc\n.zshrc\t.zshrc"):
            with self.subTest(bad=bad):
                self.list_file.write_text(bad + "\n", encoding="utf-8")

                result = self.run_check("--create")

                self.assertEqual(result.returncode, 2)
                self.assertIn("links.tsv:", result.stderr)
                self.assertNotIn("Traceback", result.stderr)
        self.assertFalse((self.home.parent / "escape").exists())


if __name__ == "__main__":
    unittest.main()
