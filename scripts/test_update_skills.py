#!/usr/bin/env python3
"""CLI integration tests for update-skills."""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("update_skills.py")


class UpdateSkillsTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        fixture = Path(self.temporary.name)
        self.source = fixture / "source"
        self.dotfiles = fixture / "dotfiles"
        self.home = fixture / "home"
        self.state = fixture / "state"
        self.backups = fixture / "backups"
        self.agents_package = self.dotfiles / "agents" / ".agents" / "skills"
        self.claude_package = self.dotfiles / "claude" / ".claude" / "skills"
        self.agents_live = self.home / ".agents" / "skills"
        self.claude_live = self.home / ".claude" / "skills"

        self.home.mkdir()
        self.agents_package.mkdir(parents=True)
        self.claude_package.mkdir(parents=True)
        for category in ("engineering", "productivity"):
            category_root = self.source / "skills" / category
            category_root.mkdir(parents=True)
            (category_root / "README.md").write_text(
                f"# {category.title()}\n", encoding="utf-8"
            )

    def make_source_skill(self, name: str, category: str = "engineering") -> Path:
        skill = self.source / "skills" / category / name
        skill.mkdir(parents=True)
        (skill / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: fixture\n---\n",
            encoding="utf-8",
        )
        return skill

    def make_package_copy(self, root: Path, name: str, source: Path) -> Path:
        destination = root / name
        shutil.copytree(source, destination)
        return destination

    def make_local_skill(self, root: Path, name: str) -> Path:
        skill = root / name
        skill.mkdir()
        (skill / "SKILL.md").write_text(
            f"---\nname: {name}\ndescription: local fixture\n---\n",
            encoding="utf-8",
        )
        return skill

    def commit_source(self, message: str) -> None:
        if not (self.source / ".git").exists():
            subprocess.run(["git", "init", "-q", str(self.source)], check=True)
            subprocess.run(
                ["git", "-C", str(self.source), "config", "user.name", "Test"],
                check=True,
            )
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(self.source),
                    "config",
                    "user.email",
                    "test@example.com",
                ],
                check=True,
            )
            subprocess.run(
                [
                    "git",
                    "-C",
                    str(self.source),
                    "config",
                    "commit.gpgsign",
                    "false",
                ],
                check=True,
            )
        subprocess.run(["git", "-C", str(self.source), "add", "."], check=True)
        subprocess.run(
            ["git", "-C", str(self.source), "commit", "-qm", message], check=True
        )

    def environment(self) -> dict[str, str]:
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

    def run_updater(
        self,
        *arguments: str,
        expected_returncode: int = 0,
        extra_environment: dict[str, str] | None = None,
        no_pull: bool = True,
    ) -> subprocess.CompletedProcess[str]:
        environment = self.environment()
        if extra_environment is not None:
            environment.update(extra_environment)
        command = [sys.executable, str(SCRIPT)]
        if no_pull:
            command.append("--no-pull")
        command.extend(arguments)
        result = subprocess.run(
            command,
            text=True,
            capture_output=True,
            env=environment,
        )
        self.assertEqual(
            expected_returncode,
            result.returncode,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        return result

    def test_routine_sync_rejects_a_manually_retargeted_managed_link(self) -> None:
        source_skill = self.make_source_skill("alpha")
        self.run_updater()
        managed_link = self.agents_live / "alpha"
        self.assertEqual(source_skill.resolve(), managed_link.resolve())

        personal = self.home / "personal-alpha"
        personal.mkdir()
        managed_link.unlink()
        managed_link.symlink_to(personal)

        result = self.run_updater(expected_returncode=2)

        self.assertIn("unmanaged symlink collision", result.stderr)
        self.assertEqual(personal.resolve(), managed_link.resolve())

    def test_migrate_archives_verified_matt_copies_and_preserves_local_skills(
        self,
    ) -> None:
        alpha = self.make_source_skill("alpha")
        zoom_out = self.make_source_skill("zoom-out")
        self.commit_source("add current and legacy skills")
        for package in (self.agents_package, self.claude_package):
            self.make_package_copy(package, "alpha", alpha)
            self.make_package_copy(package, "zoom-out", zoom_out)
            self.make_local_skill(package, "commit-message")
            self.make_local_skill(package, "typescript-object-composition")

        shutil.rmtree(zoom_out)
        self.commit_source("remove legacy skill")

        self.run_updater("--migrate", "--no-stow")

        for package in (self.agents_package, self.claude_package):
            self.assertFalse((package / "alpha").exists())
            self.assertFalse((package / "zoom-out").exists())
            self.assertTrue((package / "commit-message").is_dir())
            self.assertTrue((package / "typescript-object-composition").is_dir())
        for live in (self.agents_live, self.claude_live):
            self.assertEqual(alpha.resolve(), (live / "alpha").resolve())

        backup = next(self.backups.iterdir())
        for consumer in ("agents", "claude"):
            self.assertTrue((backup / "removed" / consumer / "alpha").is_dir())
            self.assertTrue(
                (backup / "removed" / consumer / "zoom-out").is_dir()
            )

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
    def test_migrate_converts_folded_roots_to_direct_upstream_and_stowed_local_links(
        self,
    ) -> None:
        alpha = self.make_source_skill("alpha")
        self.commit_source("add alpha")
        for package in (self.agents_package, self.claude_package):
            self.make_package_copy(package, "alpha", alpha)
            self.make_local_skill(package, "commit-message")

        (self.home / ".claude").mkdir()
        (self.home / ".claude" / "settings.json").write_text(
            "{}\n", encoding="utf-8"
        )
        for consumer in ("agents", "claude"):
            subprocess.run(
                [
                    "stow",
                    f"--dir={self.dotfiles}",
                    f"--target={self.home}",
                    "-R",
                    consumer,
                ],
                check=True,
            )

        self.assertTrue((self.home / ".agents").is_symlink())
        self.assertTrue((self.home / ".claude" / "skills").is_symlink())

        self.run_updater("--migrate")

        for live, package in (
            (self.agents_live, self.agents_package),
            (self.claude_live, self.claude_package),
        ):
            self.assertTrue(live.is_dir())
            self.assertFalse(live.is_symlink())
            self.assertTrue((live / "alpha").is_symlink())
            self.assertEqual(alpha.resolve(), (live / "alpha").resolve())
            self.assertTrue((live / "commit-message").is_symlink())
            self.assertEqual(
                (package / "commit-message").resolve(),
                (live / "commit-message").resolve(),
            )

    def test_failed_restow_restores_moved_package_copies(self) -> None:
        alpha = self.make_source_skill("alpha")
        self.commit_source("add alpha")
        for package in (self.agents_package, self.claude_package):
            self.make_package_copy(package, "alpha", alpha)

        fixture_bin = Path(self.temporary.name) / "bin"
        fixture_bin.mkdir()
        fake_stow = fixture_bin / "stow"
        fake_stow.write_text(
            "#!/bin/sh\n"
            "case \" $* \" in\n"
            "  *\" -R \"*) exit 9 ;;\n"
            "esac\n"
            "exit 0\n",
            encoding="utf-8",
        )
        fake_stow.chmod(0o755)

        self.run_updater(
            "--migrate",
            expected_returncode=2,
            extra_environment={
                "PATH": f"{fixture_bin}{os.pathsep}{os.environ['PATH']}"
            },
        )

        for package in (self.agents_package, self.claude_package):
            self.assertTrue((package / "alpha" / "SKILL.md").is_file())

    def test_migrate_rejects_a_modified_same_name_skill_without_mutation(
        self,
    ) -> None:
        alpha = self.make_source_skill("alpha")
        self.commit_source("add alpha")
        self.make_package_copy(self.agents_package, "alpha", alpha)
        (self.agents_package / "alpha" / "SKILL.md").write_text(
            "personal customization\n", encoding="utf-8"
        )

        result = self.run_updater(
            "--migrate", "--no-stow", expected_returncode=2
        )

        self.assertIn("unverified Matt copy collision", result.stderr)
        self.assertEqual(
            (self.agents_package / "alpha" / "SKILL.md").read_text(
                encoding="utf-8"
            ),
            "personal customization\n",
        )
        self.assertFalse(self.backups.exists())

    def test_routine_sync_removes_a_skill_deleted_from_the_checkout(self) -> None:
        alpha = self.make_source_skill("alpha")
        self.run_updater()
        self.assertEqual(alpha.resolve(), (self.agents_live / "alpha").resolve())

        shutil.rmtree(alpha)
        self.run_updater()

        self.assertFalse((self.agents_live / "alpha").exists())
        self.assertFalse((self.claude_live / "alpha").exists())

    def test_normal_sync_only_pulls_the_existing_checkout(self) -> None:
        self.make_source_skill("alpha")
        fixture_bin = Path(self.temporary.name) / "git-bin"
        fixture_bin.mkdir()
        event_log = Path(self.temporary.name) / "git-events"
        fake_git = fixture_bin / "git"
        fake_git.write_text(
            "#!/bin/sh\n"
            "printf '%s\\n' \"$*\" >> \"$EVENT_LOG\"\n"
            "exit 0\n",
            encoding="utf-8",
        )
        fake_git.chmod(0o755)

        self.run_updater(
            no_pull=False,
            extra_environment={
                "EVENT_LOG": str(event_log),
                "PATH": f"{fixture_bin}{os.pathsep}{os.environ['PATH']}",
            },
        )

        events = event_log.read_text(encoding="utf-8").splitlines()
        self.assertEqual(
            events,
            [
                f"-C {self.source.resolve()} status --porcelain",
                f"-C {self.source.resolve()} pull --ff-only",
            ],
        )
        self.assertFalse(any("push" in event for event in events))

    def test_migrate_verifies_a_curated_legacy_skill_across_an_upstream_rename(
        self,
    ) -> None:
        diagnose = self.make_source_skill("diagnose")
        scripts = diagnose / "scripts"
        scripts.mkdir()
        (scripts / "hitl-loop.template.sh").write_text(
            "#!/bin/sh\n", encoding="utf-8"
        )
        self.commit_source("add diagnose")
        saved_copy = Path(self.temporary.name) / "saved-diagnose"
        shutil.copytree(diagnose, saved_copy)

        renamed = diagnose.with_name("diagnosing-bugs")
        diagnose.rename(renamed)
        (renamed / "SKILL.md").write_text(
            "---\nname: diagnosing-bugs\ndescription: fixture\n---\n",
            encoding="utf-8",
        )
        self.commit_source("rename diagnose")
        for package in (self.agents_package, self.claude_package):
            self.make_package_copy(package, "diagnose", saved_copy)

        self.run_updater("--migrate", "--no-stow")

        backup = next(self.backups.iterdir())
        for consumer in ("agents", "claude"):
            self.assertTrue(
                (backup / "removed" / consumer / "diagnose").is_dir()
            )

    def test_migrate_verifies_a_resource_moved_out_of_a_current_upstream_skill(
        self,
    ) -> None:
        alpha = self.make_source_skill("alpha")
        (alpha / "SHARED.md").write_text("shared\n", encoding="utf-8")
        self.commit_source("add alpha resource")
        saved_copy = Path(self.temporary.name) / "saved-alpha"
        shutil.copytree(alpha, saved_copy)

        beta = self.make_source_skill("beta")
        (alpha / "SHARED.md").rename(beta / "SHARED.md")
        self.commit_source("move alpha resource to beta")
        for package in (self.agents_package, self.claude_package):
            self.make_package_copy(package, "alpha", saved_copy)

        self.run_updater("--migrate", "--no-stow")

        backup = next(self.backups.iterdir())
        for consumer in ("agents", "claude"):
            self.assertTrue((backup / "removed" / consumer / "alpha").is_dir())


if __name__ == "__main__":
    unittest.main()
