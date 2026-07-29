#!/usr/bin/env python3
"""Integration tests for the update-skills command."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("update_skills.py")
AGENTS_STOW_IGNORE = SCRIPT.parent.parent / "agents" / ".stow-local-ignore"
CLAUDE_STOW_IGNORE = SCRIPT.parent.parent / "claude" / ".stow-local-ignore"


class UpdateSkillsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        fixture = Path(self.temporary.name)
        self.source = fixture / "source"
        self.dotfiles = fixture / "dotfiles"
        self.state = fixture / "state"
        self.backups = fixture / "backups"
        self.home = fixture / "home"
        self.agents = self.dotfiles / "agents" / ".agents" / "skills"
        self.claude = self.dotfiles / "claude" / ".claude" / "skills"
        self.home.mkdir()
        (self.source / "skills" / "engineering").mkdir(parents=True)
        (self.source / "skills" / "productivity").mkdir(parents=True)
        (self.source / "skills" / "engineering" / "README.md").write_text(
            "# Engineering\n", encoding="utf-8"
        )
        (self.source / "skills" / "productivity" / "README.md").write_text(
            "# Productivity\n", encoding="utf-8"
        )
        self.agents.mkdir(parents=True)
        self.claude.mkdir(parents=True)

    def make_skill(self, category: str, name: str) -> Path:
        directory = self.source / "skills" / category / name
        directory.mkdir(parents=True)
        (directory / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: fixture\n---\n",
            encoding="utf-8",
        )
        return directory

    def make_copy(self, root: Path, name: str, content: str = "copy\n") -> Path:
        directory = root / name
        directory.mkdir(parents=True)
        (directory / "SKILL.md").write_text(content, encoding="utf-8")
        return directory

    def run_updater(
        self, *arguments: str, expected_returncode: int = 0
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--no-pull",
                "--no-stow",
                *arguments,
            ],
            text=True,
            capture_output=True,
            env=self.fixture_environment(),
        )
        self.assertEqual(
            expected_returncode,
            result.returncode,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        return result

    def fixture_environment(self) -> dict[str, str]:
        environment = os.environ.copy()
        environment.update(
            {
                "DOTFILES_ROOT": str(self.dotfiles),
                "SKILLS_REPO": str(self.source),
                "SKILL_SYNC_STATE_ROOT": str(self.state),
                "SKILL_SYNC_BACKUP_ROOT": str(self.backups),
                "HOME": str(self.home),
            }
        )
        return environment

    def assert_link_to(self, link: Path, expected: Path) -> None:
        self.assertTrue(link.is_symlink(), f"expected symlink: {link}")
        self.assertEqual(expected.resolve(), link.resolve())
        self.assertFalse(os.readlink(link).startswith("/"), "link must be relative")

    def seed_grouped_layout(self) -> tuple[Path, Path]:
        alpha = self.make_skill("engineering", "alpha")
        beta = self.make_skill("productivity", "beta")
        engineering = self.agents / "engineering"
        productivity = self.agents / "productivity"
        self.make_copy(engineering, "alpha")
        self.make_copy(engineering, "local-tool", "local\n")
        self.make_copy(engineering, "to-issues", "legacy\n")
        self.make_copy(engineering, "to-prd", "legacy\n")
        self.make_copy(productivity, "beta")
        self.make_copy(productivity, "local-flow", "local\n")
        self.make_copy(productivity, "teach copy", "accidental\n")
        self.make_copy(self.claude, "alpha")
        self.make_copy(self.claude, "local-claude", "local\n")
        self.make_copy(self.claude, "to-issues", "legacy\n")
        self.make_copy(self.claude, "to-prd", "legacy\n")
        return alpha, beta

    def test_migration_flattens_and_preserves_owned_skills(self) -> None:
        alpha, beta = self.seed_grouped_layout()

        self.run_updater("--dry-run", "--migrate")
        self.assertTrue((self.agents / "engineering" / "alpha").is_dir())
        self.assertTrue((self.claude / "alpha").is_dir())

        self.run_updater("--migrate")

        for root in (self.agents, self.claude):
            self.assert_link_to(root / "alpha", alpha)
            self.assert_link_to(root / "beta", beta)
            self.assert_link_to(
                root / "ENGINEERING.md",
                self.source / "skills" / "engineering" / "README.md",
            )
            self.assert_link_to(
                root / "PRODUCTIVITY.md",
                self.source / "skills" / "productivity" / "README.md",
            )

        self.assertTrue((self.agents / "local-tool").is_dir())
        self.assertTrue((self.agents / "local-flow").is_dir())
        self.assertTrue((self.claude / "local-claude").is_dir())
        self.assertFalse((self.agents / "engineering").exists())
        self.assertFalse((self.agents / "productivity").exists())
        self.assertFalse((self.agents / "teach copy").exists())
        self.assertFalse((self.agents / "to-issues").exists())
        self.assertFalse((self.agents / "to-prd").exists())
        self.assertFalse((self.claude / "to-issues").exists())
        self.assertFalse((self.claude / "to-prd").exists())
        backup = next(self.backups.iterdir())
        self.assertTrue(
            (backup / "snapshot" / "agents" / "productivity" / "teach copy").is_dir()
        )
        self.assertTrue(
            (
                backup
                / "removed"
                / "agents"
                / "grouped-engineering"
                / "to-issues"
            ).is_dir()
        )
        self.assertTrue(
            (
                backup
                / "removed"
                / "agents"
                / "grouped-engineering"
                / "to-prd"
            ).is_dir()
        )
        self.assertTrue(
            (backup / "removed" / "claude" / "legacy-to-issues").is_dir()
        )
        self.assertTrue(
            (backup / "removed" / "claude" / "legacy-to-prd").is_dir()
        )
        self.assertTrue(
            (backup / "removed" / "claude" / "copied-alpha").is_dir()
        )

    def test_removed_and_added_skills_are_reconciled(self) -> None:
        alpha = self.make_skill("engineering", "alpha")
        self.run_updater()
        self.assert_link_to(self.agents / "alpha", alpha)

        alpha.rename(self.source / "removed-alpha")
        self.run_updater()
        self.assertFalse((self.agents / "alpha").exists())
        self.assertFalse((self.claude / "alpha").exists())

        gamma = self.make_skill("engineering", "gamma")
        self.run_updater("--check", expected_returncode=1)
        self.assertFalse((self.agents / "gamma").exists())
        self.run_updater()
        self.assert_link_to(self.agents / "gamma", gamma)
        self.assert_link_to(self.claude / "gamma", gamma)

    def test_unmanaged_real_directory_collision_is_rejected(self) -> None:
        self.make_skill("engineering", "conflict")
        self.make_copy(self.agents, "conflict", "personal\n")

        result = self.run_updater(expected_returncode=2)

        self.assertIn("unverified real path collision", result.stderr)
        self.assertTrue((self.agents / "conflict").is_dir())
        self.assertFalse((self.claude / "conflict").exists())

    def test_migrate_rejects_same_name_custom_skill_without_matching_provenance(
        self,
    ) -> None:
        self.make_skill("engineering", "conflict")
        self.make_copy(
            self.agents / "engineering",
            "conflict",
            "upstream copy\n",
        )
        self.make_copy(self.claude, "conflict", "personal\n")

        result = self.run_updater("--migrate", expected_returncode=2)

        self.assertIn("unverified real path collision", result.stderr)
        self.assertTrue((self.claude / "conflict").is_dir())
        self.assertFalse(self.backups.exists())

    def test_unmanaged_symlink_collision_is_rejected(self) -> None:
        self.make_skill("engineering", "conflict")
        personal = self.dotfiles / "personal"
        personal.mkdir()
        (self.agents / "conflict").symlink_to(personal)

        result = self.run_updater(expected_returncode=2)

        self.assertIn("unmanaged symlink collision", result.stderr)
        self.assertEqual(personal.resolve(), (self.agents / "conflict").resolve())

    def test_duplicate_skill_names_are_rejected(self) -> None:
        self.make_skill("engineering", "duplicate")
        self.make_skill("productivity", "duplicate")

        result = self.run_updater("--dry-run", expected_returncode=2)

        self.assertIn("duplicate skill name", result.stderr)
        self.assertEqual(list(self.agents.iterdir()), [])
        self.assertEqual(list(self.claude.iterdir()), [])

    def test_retargeted_managed_link_is_not_deleted(self) -> None:
        alpha = self.make_skill("engineering", "alpha")
        self.run_updater()
        personal = self.dotfiles / "personal-alpha"
        personal.mkdir()
        (self.agents / "alpha").unlink()
        (self.agents / "alpha").symlink_to(personal)
        alpha.rename(self.source / "removed-alpha")

        result = self.run_updater(expected_returncode=2)

        self.assertIn("replaced outside the synchronizer", result.stderr)
        self.assertEqual(personal.resolve(), (self.agents / "alpha").resolve())

    def test_source_links_are_inferred_when_manifest_is_missing(self) -> None:
        alpha = self.make_skill("engineering", "alpha")
        self.run_updater()
        self.assert_link_to(self.agents / "alpha", alpha)
        (self.state / "managed-links.json").unlink()
        alpha.rename(self.source / "removed-alpha")

        self.run_updater()

        self.assertFalse((self.agents / "alpha").exists())
        self.assertFalse((self.claude / "alpha").exists())

    def test_normal_update_unstows_before_pull(self) -> None:
        self.make_skill("engineering", "alpha")
        fixture_bin = Path(self.temporary.name) / "bin"
        fixture_bin.mkdir()
        event_log = Path(self.temporary.name) / "events"
        for command in ("git", "stow"):
            executable = fixture_bin / command
            executable.write_text(
                "#!/bin/sh\n"
                f"printf '{command} %s\\n' \"$*\" >> \"$EVENT_LOG\"\n",
                encoding="utf-8",
            )
            executable.chmod(0o755)

        environment = self.fixture_environment()
        environment.update(
            {
                "EVENT_LOG": str(event_log),
                "PATH": f"{fixture_bin}{os.pathsep}{environment['PATH']}",
            }
        )
        result = subprocess.run(
            [sys.executable, str(SCRIPT)],
            text=True,
            capture_output=True,
            env=environment,
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        events = event_log.read_text(encoding="utf-8").splitlines()
        self.assertIn("status --porcelain", events[0])
        self.assertIn("-D --no-folding agents", events[1])
        self.assertIn("-D --no-folding claude", events[2])
        self.assertIn("pull --ff-only", events[3])
        self.assertIn("-D --no-folding agents", events[4])
        self.assertIn("-D --no-folding claude", events[5])
        self.assertIn("-R agents", events[6])
        self.assertNotIn("--no-folding", events[6])
        self.assertIn("-R claude", events[7])
        self.assertNotIn("--no-folding", events[7])

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
    def test_restow_keeps_skill_roots_real_and_links_whole_skill_directories(
        self,
    ) -> None:
        for root in (self.agents, self.claude):
            self.make_copy(root, "commit-message")
        for consumer in ("agents", "claude"):
            subprocess.run(
                [
                    "stow",
                    f"--dir={self.dotfiles}",
                    f"--target={self.home}",
                    "-R",
                    "--no-folding",
                    consumer,
                ],
                check=True,
            )
        self.assertFalse(
            (self.home / ".agents" / "skills" / "commit-message").is_symlink()
        )

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--no-pull",
            ],
            text=True,
            capture_output=True,
            env=self.fixture_environment(),
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        for consumer in (".agents", ".claude"):
            skills_root = self.home / consumer / "skills"
            self.assertTrue(skills_root.is_dir())
            self.assertFalse(skills_root.is_symlink())
            self.assertTrue(
                (skills_root / "commit-message").is_symlink(),
                f"expected whole-skill symlink: {skills_root / 'commit-message'}",
            )

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
    def test_restow_preserves_installer_owned_impeccable(self) -> None:
        for consumer, ignore_source in (
            ("agents", AGENTS_STOW_IGNORE),
            ("claude", CLAUDE_STOW_IGNORE),
        ):
            package = self.dotfiles / consumer
            (package / ".stow-local-ignore").write_text(
                ignore_source.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            skill_root = (
                self.agents if consumer == "agents" else self.claude
            )
            self.make_copy(skill_root, "impeccable", "shadow copy\n")

            live_skill = (
                self.home
                / (".agents" if consumer == "agents" else ".claude")
                / "skills"
                / "impeccable"
            )
            live_skill.mkdir(parents=True)
            (live_skill / "SKILL.md").write_text(
                "installer owned\n",
                encoding="utf-8",
            )

        result = subprocess.run(
            [
                sys.executable,
                str(SCRIPT),
                "--no-pull",
            ],
            text=True,
            capture_output=True,
            env=self.fixture_environment(),
        )

        self.assertEqual(
            result.returncode,
            0,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        for consumer in (".agents", ".claude"):
            skill_md = self.home / consumer / "skills" / "impeccable" / "SKILL.md"
            self.assertFalse(skill_md.is_symlink())
            self.assertEqual(
                skill_md.read_text(encoding="utf-8"),
                "installer owned\n",
            )


if __name__ == "__main__":
    unittest.main()
