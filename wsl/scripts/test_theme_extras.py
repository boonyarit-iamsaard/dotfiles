#!/usr/bin/env python3
"""Check pinned Theme extras and the lazydocker Theme variant contract."""

from __future__ import annotations

import json
import os
import re
import subprocess
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
THEME_EXTRAS = (
    ("tmux/.tmux/themes/extras/dark-2026.conf", "extras/tmux/dark-2026.conf"),
    ("config/lazygit/themes/dark-2026.yml", "extras/lazygit/dark-2026.yml"),
    ("config/lazydocker/themes/dark-2026.yml", "extras/lazydocker/dark-2026.yml"),
    ("config/nvim/lua/themes/dark-2026/lazygit.lua", "extras/lazyvim/lazygit.lua"),
)


class ThemeExtrasTest(unittest.TestCase):
    def setUp(self) -> None:
        self.plugin = Path(
            os.environ.get(
                "DARK_2026_NVIM_DIR",
                str(Path.home() / ".local/share/nvim/lazy/dark-2026.nvim"),
            )
        ).expanduser()
        if not self.plugin.is_dir():
            self.skipTest(f"dark-2026.nvim checkout is missing: {self.plugin}")
        lock = json.loads(
            (REPO_ROOT / "config/nvim/lazy-lock.json").read_text(encoding="utf-8")
        )
        self.pin = lock["dark-2026.nvim"]["commit"]
        result = subprocess.run(
            ["git", "-C", str(self.plugin), "cat-file", "-e", self.pin],
            capture_output=True,
        )
        if result.returncode != 0:
            self.skipTest(f"dark-2026.nvim pin {self.pin} is unavailable in {self.plugin}")

    def test_vendored_theme_extras_match_pin(self) -> None:
        for relative_path, upstream_path in THEME_EXTRAS:
            with self.subTest(file=relative_path):
                fix = (
                    f"{relative_path}: re-copy from pin {self.pin} with "
                    f"git -C {self.plugin} show {self.pin}:{upstream_path} "
                    f"> {relative_path}"
                )
                upstream = subprocess.check_output(
                    ["git", "-C", str(self.plugin), "show", f"{self.pin}:{upstream_path}"]
                )
                vendored = REPO_ROOT / relative_path
                self.assertTrue(vendored.is_file(), fix)
                self.assertEqual(upstream, vendored.read_bytes(), fix)


class LazyDockerThemeVariantTest(unittest.TestCase):
    def test_active_theme_matches_named_variant_body(self) -> None:
        directory = REPO_ROOT / "config/lazydocker"
        lines = (directory / "config.yml").read_text(encoding="utf-8").splitlines(
            keepends=True
        )
        starts = [
            index for index, line in enumerate(lines) if line.startswith("# >>> theme:")
        ]
        ends = [
            index
            for index, line in enumerate(lines)
            if line.rstrip("\r\n") == "# <<< theme"
        ]
        self.assertEqual(1, len(starts), "expected exactly one # >>> theme: <name> marker")
        self.assertEqual(1, len(ends), "expected exactly one # <<< theme marker")
        start, end = starts[0], ends[0]
        self.assertLess(start, end, "Theme variant markers must surround the YAML body")
        marker = re.fullmatch(r"# >>> theme: ([a-z0-9][a-z0-9-]*)", lines[start].rstrip("\r\n"))
        self.assertIsNotNone(marker, "expected # >>> theme: <name> marker")
        theme = directory / "themes" / f"{marker.group(1)}.yml"
        self.assertTrue(theme.is_file(), f"named Theme variant is missing: {theme}")
        theme_lines = theme.read_text(encoding="utf-8").splitlines(keepends=True)
        body_start = 0
        while body_start < len(theme_lines):
            line = theme_lines[body_start]
            if line.strip() and not line.lstrip().startswith("#"):
                break
            body_start += 1
        body = "".join(theme_lines[body_start:])
        self.assertTrue(body, f"Theme variant has no YAML body: {theme}")
        self.assertEqual(
            body,
            "".join(lines[start + 1 : end]),
            f"config/lazydocker/config.yml: replace text between markers with {theme} "
            "after removing only its leading comment lines and blank lines",
        )


if __name__ == "__main__":
    unittest.main()
