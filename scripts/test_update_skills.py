#!/usr/bin/env python3
"""Tests for the update-skills command and Sync session."""

from __future__ import annotations

import io
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from contextlib import ExitStack, redirect_stderr, redirect_stdout
from dataclasses import replace
from pathlib import Path
from unittest import mock

if __package__:
    from . import update_skills
else:
    import update_skills


SCRIPT = Path(__file__).with_name("update_skills.py")
REPO_ROOT = Path(__file__).resolve().parent.parent
CONSUMERS_BY_NAME = {consumer.name: consumer for consumer in update_skills.CONSUMERS}


class ConsumerTest(unittest.TestCase):
    def test_installer_owned_skills_match_repository_ignores(self) -> None:
        gitignore = REPO_ROOT / ".gitignore"
        gitignore_lines = gitignore.read_text(encoding="utf-8").splitlines()
        for consumer in update_skills.CONSUMERS:
            stow_ignore = REPO_ROOT / consumer.name / ".stow-local-ignore"
            stow_lines = stow_ignore.read_text(encoding="utf-8").splitlines()
            for skill in sorted(consumer.installer_owned):
                with self.subTest(consumer=consumer.name, skill=skill):
                    relative_skill = (consumer.skills_dir / skill).as_posix()
                    stow_line = "^/" + relative_skill.replace(".", r"\.")
                    self.assertIn(
                        stow_line, stow_lines,
                        f"{stow_ignore}: missing line {stow_line!r}",
                    )
                    gitignore_line = f"{consumer.name}/{relative_skill}/"
                    self.assertIn(
                        gitignore_line, gitignore_lines,
                        f"{gitignore}: missing line {gitignore_line!r}",
                    )

    def test_stow_commands_and_output_preserve_consumer_names(self) -> None:
        dotfiles = Path("/dotfiles")
        home = Path("/home/test")
        config = update_skills.Config(
            dotfiles, Path("/skills"), Path("/state"), Path("/backups"), {}
        )
        for operation, no_folding, action in (
            ("-D", True, "unstow"),
            ("-R", False, "stow"),
        ):
            with self.subTest(operation=operation):
                stdout = io.StringIO()
                with (
                    mock.patch.object(Path, "home", return_value=home),
                    mock.patch.object(update_skills.subprocess, "run") as run,
                    redirect_stdout(stdout),
                ):
                    update_skills.run_stow(config, operation, no_folding=no_folding)
                self.assertEqual(
                    [
                        mock.call(
                            [
                                "stow", f"--dir={dotfiles}", f"--target={home}",
                                operation, *(["--no-folding"] if no_folding else []),
                                consumer.name,
                            ],
                            check=True,
                        )
                        for consumer in update_skills.CONSUMERS
                    ],
                    run.call_args_list,
                )
                layout = " (--no-folding)" if no_folding else ""
                self.assertEqual(
                    f"{action}: agents{layout}\n{action}: claude{layout}\n",
                    stdout.getvalue(),
                )


class MemoryCalls:
    """Shared call order and injected failures for the in-memory adapters."""

    def __init__(self) -> None:
        self.events: list[tuple[str, Path | None]] = []
        self.failures: dict[tuple[str, Path | None], BaseException] = {}

    def record(self, operation: str, repo: Path | None = None) -> None:
        event = (operation, repo)
        self.events.append(event)
        if event in self.failures:
            raise self.failures[event]


class MemoryGitAdapter:
    def __init__(self, calls: MemoryCalls) -> None:
        self.calls = calls

    def require_checkout(self, repo: Path) -> None:
        self.calls.record("require_checkout", repo)

    def require_clean(self, repo: Path) -> None:
        self.calls.record("require_clean", repo)

    def pull(self, repo: Path) -> None:
        self.calls.record("pull", repo)


class MemoryStowAdapter:
    def __init__(self, calls: MemoryCalls) -> None:
        self.calls = calls

    def unstow(self) -> None:
        self.calls.record("unstow")

    def restow(self) -> None:
        self.calls.record("restow")


class PurePlannerTest(unittest.TestCase):
    source_root = Path("/checkout/skills")
    agents = CONSUMERS_BY_NAME["agents"].package_root(Path("/dotfiles"))
    claude = CONSUMERS_BY_NAME["claude"].package_root(Path("/dotfiles"))
    backup = Path("/fixed/session-backup")
    source = source_root / "engineering" / "alpha"

    def snapshot(self) -> update_skills.DiskSnapshot:
        paths = (
            update_skills.ConsumerPath(self.agents / "alpha"),
            update_skills.ConsumerPath(
                self.claude / "alpha", True, self.source, True, True
            ),
            *(update_skills.ConsumerPath(self.claude / name) for _, name in sorted(
                update_skills.LEGACY_ENTRIES
            )),
        )
        return update_skills.DiskSnapshot(
            skills=(update_skills.SourceSkill("alpha", self.source, self.source),),
            catalogs=(),
            resolved_skills_root=self.source_root,
            consumer_roots=tuple(
                (consumer.name, consumer.package_root(Path("/dotfiles")))
                for consumer in update_skills.CONSUMERS
            ),
            manifest_entries=frozenset(),
            inferred_managed_links=frozenset(),
            migratable_copies=frozenset(),
            consumer_paths=paths,
            grouped_entries=(),
        )

    def with_paths(
        self, snapshot: update_skills.DiskSnapshot, *states: update_skills.ConsumerPath
    ) -> update_skills.DiskSnapshot:
        paths = {state.path: state for state in snapshot.consumer_paths}
        paths.update((state.path, state) for state in states)
        return replace(snapshot, consumer_paths=tuple(paths.values()))

    def plan(
        self, snapshot: update_skills.DiskSnapshot, *, migrate: bool = False
    ) -> update_skills.Plan:
        # Every table case runs with disk, clock, and subprocess access forbidden.
        with ExitStack() as stack:
            for method in (
                "exists", "is_symlink", "is_dir", "is_file", "resolve",
                "open", "iterdir", "glob", "stat", "lstat", "readlink",
            ):
                stack.enter_context(mock.patch.object(
                    Path, method, side_effect=AssertionError(f"planner called Path.{method}")
                ))
            for owner, name in (
                (update_skills.os, "readlink"),
                (update_skills.filecmp, "cmp"),
                (update_skills.subprocess, "run"),
            ):
                stack.enter_context(mock.patch.object(
                    owner, name, side_effect=AssertionError(f"planner called {name}")
                ))
            clock = stack.enter_context(mock.patch.object(update_skills, "datetime"))
            clock.now.side_effect = AssertionError("planner read the clock")
            return update_skills.plan(snapshot, migrate=migrate, backup_dir=self.backup)

    def test_link_collision_table(self) -> None:
        target = self.agents / "alpha"
        missing = update_skills.ConsumerPath(target)
        correct = update_skills.ConsumerPath(target, True, self.source, True, True)
        old = update_skills.ConsumerPath(
            target, True, self.source_root / "old-alpha", False, False
        )
        outside = update_skills.ConsumerPath(
            target, True, Path("/installer/alpha"), False, False
        )
        directory = update_skills.ConsumerPath(target, exists=True, is_dir=True)
        file = update_skills.ConsumerPath(target, exists=True)
        link = update_skills.ActionKind.LINK
        unlink = update_skills.ActionKind.UNLINK
        move = update_skills.ActionKind.MOVE
        collision = (
            f"unverified real path collision: {target}; "
            "--migrate only accepts copies corroborated by the grouped Agents layout"
        )
        # name, disk state, ownership evidence, corroboration, migrate, actions, error
        cases = (
            ("missing", missing, "", False, False, (link,), None),
            ("already correct unmanaged link", correct, "", False, False, (), None),
            ("manifest stale link", old, "manifest", False, False, (unlink, link), None),
            ("inferred stale link", old, "inferred", False, False, (unlink, link), None),
            ("source-managed without manifest", old, "", False, False, (unlink, link), None),
            ("manifest desired retarget replaced", outside, "manifest", False, False,
             (unlink, link), None),
            ("unmanaged dangling symlink", outside, "", False, False, (),
             f"unmanaged symlink collision: {target}"),
            ("real directory migrate off", directory, "", False, False, (), collision),
            ("uncorroborated directory migrate on", directory, "", False, True, (), collision),
            ("corroborated copy migrate off", directory, "", True, False, (), collision),
            ("corroborated copy migrate on", directory, "", True, True, (move, link), None),
            ("real file migrate on", file, "", False, True, (), collision),
        )
        for name, state, ownership, corroborated, migrate, kinds, error in cases:
            with self.subTest(name=name):
                key = ("agents", "alpha")
                snapshot = replace(
                    self.with_paths(self.snapshot(), state),
                    manifest_entries=frozenset({key}) if ownership == "manifest" else frozenset(),
                    inferred_managed_links=(
                        frozenset({key}) if ownership == "inferred" else frozenset()
                    ),
                    migratable_copies=frozenset({key}) if corroborated else frozenset(),
                )
                if error:
                    with self.assertRaises(update_skills.SyncError) as raised:
                        self.plan(snapshot, migrate=migrate)
                    self.assertEqual(error, str(raised.exception))
                    continue
                result = self.plan(snapshot, migrate=migrate)
                self.assertEqual(kinds, tuple(action.kind for action in result.actions))
                self.assertEqual(self.backup, result.backup_dir)
                self.assertEqual((("agents", "alpha"), ("claude", "alpha")), result.desired_keys)
                for action in result.actions:
                    self.assertEqual(target, action.target)
                    if action.kind is link:
                        self.assertEqual(self.source, action.source)
                    if action.kind is move:
                        self.assertEqual(
                            self.backup / "removed" / "agents" / "copied-alpha",
                            action.destination,
                        )
                        self.assertTrue(action.migration)

    def test_stale_managed_link_table(self) -> None:
        target = self.agents / "obsolete"
        error = f"stale managed path was replaced outside the synchronizer: {target}"
        cases = (
            ("missing", update_skills.ConsumerPath(target), False, None),
            ("managed dangling link", update_skills.ConsumerPath(
                target, True, self.source_root / "obsolete", False, False
            ), True, None),
            ("managed live link", update_skills.ConsumerPath(
                target, True, self.source_root / "obsolete", True, True
            ), True, None),
            ("retargeted link", update_skills.ConsumerPath(
                target, True, Path("/installer/obsolete"), True, True
            ), False, error),
            ("retargeted dangling link", update_skills.ConsumerPath(
                target, True, Path("/installer/obsolete"), False, False
            ), False, error),
            ("replaced real directory", update_skills.ConsumerPath(
                target, exists=True, is_dir=True
            ), False, error),
        )
        for name, state, removed, error in cases:
            for migrate in (False, True):
                with self.subTest(name=name, migrate=migrate):
                    snapshot = replace(
                        self.with_paths(self.snapshot(), state),
                        manifest_entries=frozenset({("agents", "obsolete")}),
                    )
                    if error:
                        with self.assertRaises(update_skills.SyncError) as raised:
                            self.plan(snapshot, migrate=migrate)
                        self.assertEqual(error, str(raised.exception))
                    else:
                        result = self.plan(snapshot, migrate=migrate)
                        stale = [action for action in result.actions if action.target == target]
                        self.assertEqual(
                            (update_skills.ActionKind.UNLINK,) if removed else (),
                            tuple(action.kind for action in stale),
                        )

    def test_unknown_real_path_table(self) -> None:
        claude = CONSUMERS_BY_NAME["claude"]
        personal = sorted(claude.personal)[0]
        installer = sorted(claude.installer_owned)[0]
        error = (
            f"unknown real skill path: {self.claude / 'retired'}; it is neither a "
            "personal skill nor installer-owned, so remove it or declare it "
            "personal in CONSUMERS"
        )
        cases = (
            ("stale upstream copy", "retired", error),
            ("personal skill", personal, None),
            ("installer-owned skill", installer, None),
            ("package readme", update_skills.README_FILENAME, None),
        )
        for name, entry, expected in cases:
            with self.subTest(name=name):
                snapshot = self.with_paths(
                    self.snapshot(),
                    update_skills.ConsumerPath(self.claude / entry, exists=True, is_dir=True),
                )
                if expected:
                    with self.assertRaises(update_skills.SyncError) as raised:
                        self.plan(snapshot)
                    self.assertEqual(expected, str(raised.exception))
                else:
                    self.plan(snapshot)

    def test_grouped_and_legacy_migration_table(self) -> None:
        group = self.agents / "engineering"
        custom = self.agents / "local-tool"
        legacy = self.claude / "to-issues"
        entries = tuple(group / name for name in (
            "README.md", "alpha", "local-tool", "teach copy", "to-issues", "to-prd"
        ))
        cases = (
            ("migrate off preserves layout", False, update_skills.ConsumerPath(custom), None),
            ("migrate on flattens custom and archives", True,
             update_skills.ConsumerPath(custom), None),
            ("custom directory collision", True,
             update_skills.ConsumerPath(custom, exists=True, is_dir=True),
             f"cannot flatten custom skill 'local-tool'; target already exists: {custom}"),
            ("custom dangling symlink collision", True,
             update_skills.ConsumerPath(custom, True, Path("/missing/custom")),
             f"cannot flatten custom skill 'local-tool'; target already exists: {custom}"),
            ("migrate off ignores custom collision", False,
             update_skills.ConsumerPath(custom, exists=True, is_dir=True), None),
        )
        for name, migrate, custom_state, error in cases:
            with self.subTest(name=name):
                snapshot = replace(
                    self.with_paths(
                        self.snapshot(), custom_state,
                        update_skills.ConsumerPath(legacy, True, Path("/missing/legacy")),
                    ),
                    grouped_entries=(("engineering", entries),),
                )
                if error:
                    with self.assertRaises(update_skills.SyncError) as raised:
                        self.plan(snapshot, migrate=migrate)
                    self.assertEqual(error, str(raised.exception))
                    continue
                result = self.plan(snapshot, migrate=migrate)
                moves = [action for action in result.actions if action.migration]
                expected = (
                    (
                        (group / "local-tool", custom),
                        (group, self.backup / "removed" / "agents" / "grouped-engineering"),
                        (legacy, self.backup / "removed" / "claude" / "legacy-to-issues"),
                    )
                    if migrate else ()
                )
                self.assertEqual(
                    expected, tuple((action.target, action.destination) for action in moves)
                )
                self.assertTrue(all(action.kind is update_skills.ActionKind.MOVE for action in moves))
                self.assertEqual(self.backup, result.backup_dir)
                self.assertEqual(migrate, result.needs_migration_backup)


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
        self.extras = fixture / "extras"
        self.agents = CONSUMERS_BY_NAME["agents"].package_root(self.dotfiles)
        self.claude = CONSUMERS_BY_NAME["claude"].package_root(self.dotfiles)
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
        self.calls = MemoryCalls()
        self.git = MemoryGitAdapter(self.calls)
        self.stow = MemoryStowAdapter(self.calls)
        self.stdout = io.StringIO()
        self.stderr = io.StringIO()

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
                "EXTRA_CHECKOUTS_ROOT": str(self.extras),
                "HOME": str(self.home),
            }
        )
        return environment

    def session(self, *arguments: str) -> update_skills.SyncSession:
        with mock.patch.dict(os.environ, self.fixture_environment()):
            config = update_skills.config_from_environment()
        return update_skills.SyncSession(
            config, self.git, self.stow, **vars(update_skills.parse_args(list(arguments)))
        )

    def run_session(self, *arguments: str) -> int:
        with redirect_stdout(self.stdout), redirect_stderr(self.stderr):
            return self.session(*arguments).run()

    def assert_before(
        self, before: tuple[str, Path | None], after: tuple[str, Path | None]
    ) -> None:
        remaining = iter(self.calls.events)
        self.assertIn(before, remaining)
        self.assertIn(after, remaining)

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
        self.make_copy(self.claude, "runbook", "local\n")
        self.make_copy(self.claude, "to-issues", "legacy\n")
        self.make_copy(self.claude, "to-prd", "legacy\n")
        return alpha, beta

    def test_session_uses_fixed_backup_without_reading_clock(self) -> None:
        self.seed_grouped_layout()
        session = self.session("--migrate", "--no-pull", "--no-stow")
        session.backup_dir = self.backups / "fixed-session"
        with mock.patch.object(update_skills, "datetime") as clock:
            clock.now.side_effect = AssertionError("fixed backup must not read the clock")
            with redirect_stdout(self.stdout), redirect_stderr(self.stderr):
                self.assertEqual(0, session.run(), self.stderr.getvalue())
        self.assertTrue((session.backup_dir / "snapshot" / "claude" / "alpha").is_dir())
        self.assertTrue((session.backup_dir / "removed" / "claude" / "copied-alpha").is_dir())

    def test_session_reads_clock_once(self) -> None:
        session = self.session("--dry-run")
        with mock.patch.object(update_skills, "datetime") as clock:
            clock.now.return_value.strftime.return_value = "fixed-timestamp"
            with mock.patch.object(update_skills, "print_plan") as print_plan:
                with redirect_stdout(self.stdout), redirect_stderr(self.stderr):
                    self.assertEqual(0, session.run())
            clock.now.assert_called_once_with()
            self.assertEqual(
                self.backups / "fixed-timestamp", print_plan.call_args.args[0].backup_dir
            )

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
        self.assertTrue((self.claude / "runbook").is_dir())
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
        self.assertEqual([], list(self.agents.iterdir()))
        self.assertEqual([], list(self.claude.iterdir()))

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
        alpha = self.make_skill("engineering", "alpha")
        humanizer = self.extras / "humanizer"
        execute_plan = update_skills.execute_plan
        write_manifest = update_skills.write_manifest
        make_plan = update_skills.plan
        print_plan = update_skills.print_plan

        def plan(
            snapshot: update_skills.DiskSnapshot, *, migrate: bool, backup_dir: Path
        ) -> update_skills.Plan:
            self.calls.record("plan")
            return make_plan(snapshot, migrate=migrate, backup_dir=backup_dir)

        def show_plan(plan: update_skills.Plan) -> None:
            self.calls.record("print_plan")
            print_plan(plan)

        def execute(config: update_skills.Config, plan: update_skills.Plan) -> None:
            self.calls.record("execute")
            execute_plan(config, plan)

        def manifest(
            config: update_skills.Config, desired_keys: tuple[tuple[str, str], ...]
        ) -> None:
            self.calls.record("manifest")
            write_manifest(config, desired_keys)

        with (
            mock.patch.object(update_skills, "execute_plan", side_effect=execute),
            mock.patch.object(update_skills, "write_manifest", side_effect=manifest),
            mock.patch.object(update_skills, "plan", plan),
            mock.patch.object(update_skills, "print_plan", side_effect=show_plan),
        ):
            self.assertEqual(0, self.run_session())

        for repo in (self.source, humanizer):
            self.assert_before(("require_clean", repo), ("pull", humanizer))
        self.assert_before(("require_checkout", humanizer), ("require_clean", self.source))
        self.assert_before(("pull", humanizer), ("unstow", None))
        self.assert_before(("unstow", None), ("pull", self.source))
        self.assert_before(("pull", self.source), ("plan", None))
        self.assert_before(("plan", None), ("print_plan", None))
        self.assert_before(("print_plan", None), ("execute", None))
        self.assert_before(("execute", None), ("manifest", None))
        self.assert_before(("manifest", None), ("restow", None))
        self.assertEqual(("restow", None), next(reversed(self.calls.events)))
        self.assert_link_to(self.agents / "alpha", alpha)
        self.assertTrue((self.state / "managed-links.json").is_file())

    def test_missing_extra_checkout_fails_before_any_pull(self) -> None:
        humanizer = self.extras / "humanizer"
        self.calls.failures[("require_checkout", humanizer)] = update_skills.SyncError(
            f"checkout not found at {humanizer}; clone it with: "
            f"git clone https://github.com/blader/humanizer.git {humanizer}"
        )

        self.assertEqual(2, self.run_session())

        self.assertIn(
            "git clone https://github.com/blader/humanizer.git", self.stderr.getvalue()
        )
        self.assertEqual([("require_checkout", humanizer)], self.calls.events)

    def test_dirty_checkout_prevents_all_pulls_and_unlinking(self) -> None:
        humanizer = self.extras / "humanizer"
        self.calls.failures[("require_clean", humanizer)] = update_skills.SyncError(
            "checkout has local changes"
        )

        self.assertEqual(2, self.run_session())

        self.assertFalse(
            any(
                operation in ("pull", "unstow", "restow")
                for operation, _ in self.calls.events
            )
        )

    def test_skills_pull_failure_relinks_consumers(self) -> None:
        self.calls.failures[("pull", self.source)] = subprocess.CalledProcessError(
            1, ["git", "pull", "--ff-only"]
        )

        self.assertEqual(2, self.run_session())

        self.assert_before(("unstow", None), ("pull", self.source))
        self.assert_before(("pull", self.source), ("restow", None))
        self.assertEqual(("restow", None), next(reversed(self.calls.events)))
        self.assertFalse((self.state / "managed-links.json").exists())

    def test_execution_failure_relinks_without_rolling_back_partial_plan(self) -> None:
        self.make_skill("engineering", "alpha")
        execute_plan = update_skills.execute_plan
        applied: list[Path] = []

        def fail_midway(config: update_skills.Config, plan: update_skills.Plan) -> None:
            first, *_ = plan.actions
            execute_plan(config, replace(plan, actions=(first,)))
            applied.append(first.target)
            self.calls.record("execute_failure")
            raise update_skills.SyncError("execution stopped midway")

        with mock.patch.object(update_skills, "execute_plan", side_effect=fail_midway):
            self.assertEqual(2, self.run_session())

        self.assert_before(("execute_failure", None), ("restow", None))
        self.assertTrue(all(path.is_symlink() for path in applied))
        self.assertFalse((self.state / "managed-links.json").exists())
        self.assertIn("execution stopped midway", self.stderr.getvalue())

    def test_unexpected_exception_relinks_then_propagates(self) -> None:
        failure = ValueError("unexpected pull failure")
        self.calls.failures[("pull", self.source)] = failure

        with self.assertRaises(ValueError) as raised:
            self.run_session()

        self.assertIs(failure, raised.exception)
        self.assert_before(("pull", self.source), ("restow", None))
        self.assertEqual(("restow", None), next(reversed(self.calls.events)))

    def test_recovery_failure_is_reported_without_masking_original_exception(self) -> None:
        failure = ValueError("original failure")
        self.calls.failures[("pull", self.source)] = failure
        self.calls.failures[("restow", None)] = RuntimeError("relink failure")

        with self.assertRaises(ValueError) as raised:
            self.run_session()

        self.assertIs(failure, raised.exception)
        self.assertIn(
            "error: failed to restore Stow layout: relink failure",
            self.stderr.getvalue(),
        )

    def test_extra_checkout_pull_failure_does_not_relink(self) -> None:
        humanizer = self.extras / "humanizer"
        self.calls.failures[("pull", humanizer)] = OSError("extra pull failed")

        self.assertEqual(2, self.run_session())

        self.assertNotIn(("unstow", None), self.calls.events)
        self.assertNotIn(("restow", None), self.calls.events)
        self.assertNotIn(("pull", self.source), self.calls.events)

    def test_no_stow_still_pulls_and_applies(self) -> None:
        alpha = self.make_skill("engineering", "alpha")

        self.assertEqual(0, self.run_session("--no-stow"))

        self.assertIn(("pull", self.source), self.calls.events)
        self.assertIn(("pull", self.extras / "humanizer"), self.calls.events)
        self.assertNotIn(("unstow", None), self.calls.events)
        self.assertNotIn(("restow", None), self.calls.events)
        self.assert_link_to(self.agents / "alpha", alpha)

    def test_read_only_modes_skip_git_and_stow(self) -> None:
        self.make_skill("engineering", "alpha")
        for mode, expected in (("--check", 1), ("--dry-run", 0)):
            with self.subTest(mode=mode):
                self.assertEqual(expected, self.run_session(mode))
                self.assertEqual([], self.calls.events)
                self.assertEqual([], list(self.agents.iterdir()))
                self.assertFalse((self.state / "managed-links.json").exists())

    def test_no_pull_unlinks_only_after_planning_and_still_relinks(self) -> None:
        self.make_skill("engineering", "alpha")
        planner = update_skills.plan

        def record_plan(
            snapshot: update_skills.DiskSnapshot, *, migrate: bool, backup_dir: Path
        ) -> update_skills.Plan:
            self.calls.record("plan")
            return planner(snapshot, migrate=migrate, backup_dir=backup_dir)

        with mock.patch.object(update_skills, "plan", record_plan):
            self.assertEqual(0, self.run_session("--no-pull"))

        self.assert_before(("plan", None), ("unstow", None))
        self.assert_before(("unstow", None), ("restow", None))
        self.assertFalse(
            any(
                operation in ("require_checkout", "require_clean", "pull")
                for operation, _ in self.calls.events
            )
        )

    def test_empty_applying_plan_still_relinks_consumers(self) -> None:
        self.assertEqual(0, self.run_session("--no-pull", "--no-stow"))
        self.calls.events.clear()

        self.assertEqual(0, self.run_session("--no-pull"))

        self.assertEqual([("restow", None)], self.calls.events)
        self.assertEqual(0, self.run_session("--check"))
        self.assertEqual([("restow", None)], self.calls.events)

    def test_planning_failure_after_unlink_relinks_consumers(self) -> None:
        self.make_skill("engineering", "duplicate")
        self.make_skill("productivity", "duplicate")

        self.assertEqual(2, self.run_session())

        self.assert_before(("unstow", None), ("restow", None))
        self.assertIn("duplicate skill name", self.stderr.getvalue())
        self.assertFalse((self.state / "managed-links.json").exists())

    def test_partial_unstow_failure_still_relinks_consumers(self) -> None:
        self.calls.failures[("unstow", None)] = OSError("second consumer failed")

        self.assertEqual(2, self.run_session())

        self.assert_before(("unstow", None), ("restow", None))
        self.assertNotIn(("pull", self.source), self.calls.events)

    def test_handled_error_keeps_exit_code_when_recovery_also_fails(self) -> None:
        self.calls.failures[("pull", self.source)] = update_skills.SyncError(
            "original pull failure"
        )
        self.calls.failures[("restow", None)] = ValueError("relink failure")

        self.assertEqual(2, self.run_session())

        self.assertIn("error: original pull failure", self.stderr.getvalue())
        self.assertIn(
            "error: failed to restore Stow layout: relink failure",
            self.stderr.getvalue(),
        )

    def test_session_migrate_option_reconciles_copied_skills(self) -> None:
        alpha = self.make_skill("engineering", "alpha")
        self.make_copy(self.agents / "engineering", "alpha")
        self.make_copy(self.claude, "alpha")

        self.assertEqual(
            0,
            self.run_session("--migrate", "--no-pull"),
            msg=self.stderr.getvalue(),
        )

        for root in (self.agents, self.claude):
            self.assert_link_to(root / "alpha", alpha)
        self.assertFalse((self.agents / "engineering").exists())
        backup = next(self.backups.iterdir())
        self.assertTrue(
            (backup / "snapshot" / "agents" / "engineering" / "alpha").is_dir()
        )
        self.assertTrue((backup / "snapshot" / "claude" / "alpha").is_dir())
        self.assertTrue(
            (backup / "removed" / "agents" / "grouped-engineering" / "alpha").is_dir()
        )
        self.assertTrue((backup / "removed" / "claude" / "copied-alpha").is_dir())
        self.assertEqual(("restow", None), next(reversed(self.calls.events)))

    def test_empty_plan_restow_failure_attempts_recovery(self) -> None:
        self.assertEqual(0, self.run_session("--no-pull", "--no-stow"))
        self.calls.events.clear()
        self.calls.failures[("restow", None)] = OSError("restow stopped after unlink")

        self.assertEqual(2, self.run_session("--no-pull"))

        self.assertEqual(2, self.calls.events.count(("restow", None)))
        self.assertIn("failed to restore Stow layout", self.stderr.getvalue())

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
    def test_restow_keeps_skill_roots_real_and_links_whole_skill_directories(
        self,
    ) -> None:
        for root in (self.agents, self.claude):
            self.make_copy(root, "commit-message")
        for consumer in update_skills.CONSUMERS:
            subprocess.run(
                [
                    "stow",
                    f"--dir={self.dotfiles}",
                    f"--target={self.home}",
                    "-R",
                    "--no-folding",
                    consumer.name,
                ],
                check=True,
            )
        self.assertFalse(
            (CONSUMERS_BY_NAME["agents"].live_root(self.home) / "commit-message")
            .is_symlink()
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
            0,
            result.returncode,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        for consumer in update_skills.CONSUMERS:
            skills_root = consumer.live_root(self.home)
            self.assertTrue(skills_root.is_dir())
            self.assertFalse(skills_root.is_symlink())
            self.assertTrue(
                (skills_root / "commit-message").is_symlink(),
                f"expected whole-skill symlink: {skills_root / 'commit-message'}",
            )

    @unittest.skipUnless(shutil.which("stow"), "GNU Stow is required")
    def test_restow_preserves_installer_owned_impeccable(self) -> None:
        for consumer in update_skills.CONSUMERS:
            package = self.dotfiles / consumer.name
            ignore_source = REPO_ROOT / consumer.name / ".stow-local-ignore"
            (package / ".stow-local-ignore").write_text(
                ignore_source.read_text(encoding="utf-8"),
                encoding="utf-8",
            )
            skill_root = consumer.package_root(self.dotfiles)
            self.make_copy(skill_root, "impeccable", "shadow copy\n")

            live_skill = consumer.live_root(self.home) / "impeccable"
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
            0,
            result.returncode,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        for consumer in update_skills.CONSUMERS:
            skill_md = consumer.live_root(self.home) / "impeccable" / "SKILL.md"
            self.assertFalse(skill_md.is_symlink())
            self.assertEqual(
                "installer owned\n",
                skill_md.read_text(encoding="utf-8"),
            )


if __name__ == "__main__":
    unittest.main()
