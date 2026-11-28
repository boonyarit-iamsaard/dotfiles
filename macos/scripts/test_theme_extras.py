#!/usr/bin/env python3
"""Check pinned Theme extras, the shared theme links, the lazydocker contract and the active theme of each macOS tool."""

from __future__ import annotations

import json
import os
import re
import subprocess
import unittest
import urllib.error
import urllib.request
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
SHARED_THEMES = REPO_ROOT.parent / "shared/themes"
# Paths are relative to SHARED_THEMES.
THEME_EXTRAS = (
    ("tmux/extras/dark-2026.conf", "extras/tmux/dark-2026.conf"),
    ("lazygit/dark-2026.yml", "extras/lazygit/dark-2026.yml"),
    ("lazydocker/dark-2026.yml", "extras/lazydocker/dark-2026.yml"),
    ("nvim/dark-2026/lazygit.lua", "extras/lazyvim/lazygit.lua"),
    ("btop/dark-2026.theme", "extras/btop/dark-2026.theme"),
)
# Each macOS theme path and the shared/themes path it must link to.
SHARED_THEME_LINKS = (
    (".config/btop/themes", "btop"),
    (".config/lazydocker/themes", "lazydocker"),
    (".config/lazygit/themes", "lazygit"),
    (".config/nvim/lua/themes", "nvim"),
    (".config/starship.catppuccin-macchiato.toml", "starship/catppuccin-macchiato.toml"),
    (".config/starship.catppuccin-mocha.toml", "starship/catppuccin-mocha.toml"),
    (".config/starship.default-dark-modern.toml", "starship/default-dark-modern.toml"),
    (".tmux/themes", "tmux"),
)
# Each tool still themed in tracked config, as a regex, must name Catppuccin Mocha;
# set-theme --check covers starship, LazyGit, tmux and Ghostty.
ACTIVE_THEMES = (
    (".config/nvim/lua/plugins/colorscheme.lua", r'flavour = "mocha"'),
    (".config/nvim/lua/plugins/colorscheme.lua", r'colorscheme = "catppuccin-mocha"'),
    (".config/lazydocker/config.yml", r"^# >>> theme: catppuccin-mocha$"),
    (".config/btop/btop.conf", r'^color_theme = "catppuccin-mocha\.theme"$'),
    (".config/superfile/config.toml", r"^theme = 'catppuccin-mocha'$"),
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
            (REPO_ROOT / ".config/nvim/lazy-lock.json").read_text(encoding="utf-8")
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
                    f"> shared/themes/{relative_path}"
                )
                upstream = subprocess.check_output(
                    ["git", "-C", str(self.plugin), "show", f"{self.pin}:{upstream_path}"]
                )
                vendored = SHARED_THEMES / relative_path
                self.assertTrue(vendored.is_file(), fix)
                self.assertEqual(upstream, vendored.read_bytes(), fix)


class CatppuccinThemesTest(unittest.TestCase):
    def test_vendored_catppuccin_files_match_pin(self) -> None:
        pins = json.loads((SHARED_THEMES / "catppuccin.json").read_text(encoding="utf-8"))
        for port, pin in pins.items():
            for relative_path, upstream_path in pin["files"].items():
                with self.subTest(file=relative_path):
                    url = (
                        f"https://raw.githubusercontent.com/catppuccin/{port}/"
                        f"{pin['commit']}/{upstream_path}"
                    )
                    try:
                        with urllib.request.urlopen(url, timeout=20) as response:
                            upstream = response.read()
                    except (urllib.error.URLError, TimeoutError) as error:
                        self.skipTest(f"cannot fetch {url}: {error}")
                    vendored = SHARED_THEMES / relative_path
                    fix = f"shared/themes/{relative_path}: re-download from {url}"
                    self.assertTrue(vendored.is_file(), fix)
                    self.assertEqual(upstream, vendored.read_bytes(), fix)


class SharedThemeLinksTest(unittest.TestCase):
    def test_theme_paths_link_into_shared_themes(self) -> None:
        for relative_path, shared_path in SHARED_THEME_LINKS:
            with self.subTest(path=relative_path):
                path = REPO_ROOT / relative_path
                self.assertTrue(path.is_symlink(), f"{relative_path} must be a symlink")
                self.assertFalse(
                    Path(os.readlink(path)).is_absolute(),
                    f"{relative_path} must be a relative symlink",
                )
                self.assertEqual((SHARED_THEMES / shared_path).resolve(), path.resolve())
                self.assertTrue(path.exists(), f"{relative_path} is a broken link")


class LazyDockerThemeVariantTest(unittest.TestCase):
    def test_active_theme_matches_named_variant_body(self) -> None:
        directory = REPO_ROOT / ".config/lazydocker"
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
            f".config/lazydocker/config.yml: replace text between markers with {theme} "
            "after removing only its leading comment lines and blank lines",
        )


class ActiveThemeScopeTest(unittest.TestCase):
    def test_every_macos_tool_runs_catppuccin_mocha(self) -> None:
        for relative_path, pattern in ACTIVE_THEMES:
            with self.subTest(path=relative_path, pattern=pattern):
                text = (REPO_ROOT / relative_path).read_text(encoding="utf-8")
                self.assertIsNotNone(
                    re.search(pattern, text, re.MULTILINE),
                    f"{relative_path} is not on Catppuccin Mocha; "
                    "activate the theme in every tool in the macos/README.md theme table",
                )


if __name__ == "__main__":
    unittest.main()
