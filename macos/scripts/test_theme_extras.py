#!/usr/bin/env python3
"""Check pinned Theme extras, the shared theme links, the lazydocker contract and the theme-neutral Neovim config."""

from __future__ import annotations

import json
import os
import re
import subprocess
import tempfile
import tomllib
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


class SuperfileThemesTest(unittest.TestCase):
    def test_vendored_superfile_themes_match_pin(self) -> None:
        directory = REPO_ROOT / ".config/superfile"
        pin = json.loads((directory / "upstream.json").read_text(encoding="utf-8"))
        for relative_path, upstream_path in pin["files"].items():
            with self.subTest(file=relative_path):
                url = f"https://raw.githubusercontent.com/{pin['repo']}/{pin['commit']}/{upstream_path}"
                try:
                    with urllib.request.urlopen(url, timeout=20) as response:
                        upstream = response.read()
                except (urllib.error.URLError, TimeoutError) as error:
                    self.skipTest(f"cannot fetch {url}: {error}")
                vendored = directory / relative_path
                fix = f"macos/.config/superfile/{relative_path}: re-download from {url}"
                self.assertTrue(vendored.is_file(), fix)
                self.assertEqual(upstream, vendored.read_bytes(), fix)


    def test_every_superfile_theme_sets_the_pinned_themes_keys(self) -> None:
        directory = REPO_ROOT / ".config/superfile/theme"
        keys = set(tomllib.loads((directory / "catppuccin-mocha.toml").read_text(encoding="utf-8")))
        for theme in sorted(directory.glob("*.toml")):
            with self.subTest(theme=theme.name):
                self.assertEqual(set(tomllib.loads(theme.read_text(encoding="utf-8"))), keys)


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
    def test_generated_config_holds_the_named_variant_body(self) -> None:
        directory = REPO_ROOT / ".config/lazydocker"
        listed = subprocess.run(
            [str(REPO_ROOT / "scripts/set-theme"), "--list"], capture_output=True, text=True, check=True
        ).stdout
        for name in listed.replace("*", "").split():
            with self.subTest(theme=name), tempfile.TemporaryDirectory() as home:
                subprocess.run(
                    [str(REPO_ROOT / "scripts/set-theme"), "--home", home, name],
                    capture_output=True,
                    check=True,
                    env={**os.environ, "XDG_STATE_HOME": home},
                )
                lines = (Path(home) / ".config/lazydocker/config.yml").read_text(encoding="utf-8").splitlines(
                    keepends=True
                )
                self.assertEqual(lines.count(f"# >>> theme: {name}\n"), 1, "expected one # >>> theme: <name> marker")
                self.assertEqual(lines.count("# <<< theme\n"), 1, "expected one # <<< theme marker")
                start, end = lines.index(f"# >>> theme: {name}\n"), lines.index("# <<< theme\n")
                self.assertLess(start, end, "Theme variant markers must surround the YAML body")
                theme_lines = (directory / "themes" / f"{name}.yml").read_text(encoding="utf-8").splitlines(
                    keepends=True
                )
                # Scanned line by line, independently of set-theme's regex.
                body_start = 0
                while body_start < len(theme_lines):
                    line = theme_lines[body_start]
                    if line.strip() and not line.lstrip().startswith("#"):
                        break
                    body_start += 1
                body = "".join(theme_lines[body_start:]).rstrip("\n") + "\n"
                self.assertEqual(
                    body,
                    "".join(lines[start + 1 : end]),
                    f"set-theme must copy {name}.yml between the markers, "
                    "removing only its leading comment lines and blank lines",
                )


class NeovimThemeSelectionTest(unittest.TestCase):
    def test_macchiato_lazygit_override_matches_the_shared_lazygit_theme(self) -> None:
        # Scans each file's own syntax: YAML `key:` then `- '#hex'`, Lua `key = { "#hex"`.
        yml = (SHARED_THEMES / "lazygit/catppuccin-macchiato.yml").read_text(encoding="utf-8")
        lua = (REPO_ROOT / ".config/nvim/lua/macos_themes/catppuccin-macchiato.lua").read_text(encoding="utf-8")
        expected = dict(re.findall(r"(\w+):\s*\n\s*- '(#[0-9a-f]{6})'", yml))
        expected["authorColors"] = re.search(r"'\*': '(#[0-9a-f]{6})'", yml).group(1)
        actual = dict(re.findall(r'(\w+) = \{ (?:\[\'"\*"\'\] = )?"(#[0-9a-f]{6})"', lua))
        self.assertEqual(len(expected), 13)
        self.assertEqual(actual, expected)


    def test_tracked_colorscheme_config_names_no_theme(self) -> None:
        text = (REPO_ROOT / ".config/nvim/lua/plugins/colorscheme.lua").read_text(encoding="utf-8")
        self.assertIsNone(
            re.search(r'(colorscheme|flavour|import)\s*=\s*"', text),
            "colorscheme.lua must take the theme from active_theme, which set-theme writes",
        )


if __name__ == "__main__":
    unittest.main()
