#!/usr/bin/env python3
"""Synchronize a read-only skills checkout into dotfiles Stow packages."""

from __future__ import annotations

import argparse
import filecmp
import json
import os
import shutil
import subprocess
import sys
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
from pathlib import Path
from typing import Iterable, TypedDict


CATEGORIES = ("engineering", "productivity")
CONSUMERS = ("agents", "claude")
README_FILENAME = "README.md"
LEGACY_ENTRIES = frozenset(
    {
        ("claude", "to-issues"),
        ("claude", "to-prd"),
    }
)
GROUPED_LEGACY_SKILLS = frozenset({"to-issues", "to-prd", "teach copy"})
MANIFEST_VERSION = 1


class SyncError(RuntimeError):
    """A safe reconciliation plan cannot be produced or executed."""


class ActionKind(str, Enum):
    MOVE = "move"
    UNLINK = "unlink"
    LINK = "link"


class ManifestLink(TypedDict):
    consumer: str
    name: str


class ManifestPayload(TypedDict):
    version: int
    links: list[ManifestLink]


@dataclass(frozen=True)
class Config:
    dotfiles_root: Path
    skills_repo: Path
    state_root: Path
    backup_root: Path

    @property
    def skills_root(self) -> Path:
        return self.skills_repo / "skills"

    def consumer_root(self, consumer: str) -> Path:
        if consumer == "agents":
            return self.dotfiles_root / "agents" / ".agents" / "skills"
        if consumer == "claude":
            return self.dotfiles_root / "claude" / ".claude" / "skills"
        raise ValueError(f"unknown consumer: {consumer}")


@dataclass(frozen=True)
class Action:
    kind: ActionKind
    label: str
    target: Path
    source: Path | None = None
    destination: Path | None = None
    migration: bool = False

    def __post_init__(self) -> None:
        if self.kind is ActionKind.MOVE and self.destination is None:
            raise ValueError("move actions require a destination")
        if self.kind is ActionKind.LINK and self.source is None:
            raise ValueError("link actions require a source")
        if self.kind is ActionKind.UNLINK and (
            self.source is not None or self.destination is not None
        ):
            raise ValueError("unlink actions accept only a target")


@dataclass(frozen=True)
class Plan:
    actions: tuple[Action, ...]
    desired_keys: tuple[tuple[str, str], ...]
    backup_dir: Path

    @property
    def needs_migration_backup(self) -> bool:
        return any(action.migration for action in self.actions)


def is_within(path: Path, parent: Path) -> bool:
    try:
        path.relative_to(parent)
    except ValueError:
        return False
    return True


def resolved_link(path: Path) -> Path:
    return (path.parent / os.readlink(path)).resolve(strict=False)


class Reconciler:
    def __init__(self, config: Config, migrate: bool) -> None:
        self.config = config
        self.migrate = migrate
        self.skills = self._discover_skills()
        self.desired = self._build_desired()
        self.previously_managed = (
            self._read_manifest() | self._infer_managed_links()
        )
        self.migratable_copies = self._discover_migratable_copies()
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        self.backup_dir = config.backup_root / timestamp

    def _discover_skills(self) -> dict[str, Path]:
        if not self.config.skills_root.is_dir():
            raise SyncError(
                f"skills checkout not found at {self.config.skills_repo}"
            )

        discovered: dict[str, Path] = {}
        for category in CATEGORIES:
            category_root = self.config.skills_root / category
            catalog = category_root / README_FILENAME
            if not catalog.is_file():
                raise SyncError(f"missing category catalog: {catalog}")

            for skill_md in sorted(category_root.glob("*/SKILL.md")):
                name = skill_md.parent.name
                previous = discovered.get(name)
                if previous is not None:
                    raise SyncError(
                        f"duplicate skill name {name!r}: {previous} and {skill_md.parent}"
                    )
                discovered[name] = skill_md.parent

        return discovered

    def _build_desired(self) -> dict[tuple[str, str], Path]:
        desired: dict[tuple[str, str], Path] = {}
        for consumer in CONSUMERS:
            for name, source in self.skills.items():
                desired[(consumer, name)] = source
            for category in CATEGORIES:
                desired[(consumer, f"{category.upper()}.md")] = (
                    self.config.skills_root / category / README_FILENAME
                )
        return desired

    def _read_manifest(self) -> set[tuple[str, str]]:
        manifest = self.config.state_root / "managed-links.json"
        if not manifest.exists():
            return set()
        try:
            payload = json.loads(manifest.read_text(encoding="utf-8"))
            if payload.get("version") != MANIFEST_VERSION:
                raise ValueError("unsupported manifest version")
            return {
                (entry["consumer"], entry["name"])
                for entry in payload.get("links", [])
            }
        except (OSError, ValueError, KeyError, TypeError) as error:
            raise SyncError(f"invalid sync manifest {manifest}: {error}") from error

    def _is_source_managed_link(self, path: Path) -> bool:
        if not path.is_symlink():
            return False
        return is_within(
            resolved_link(path), self.config.skills_root.resolve(strict=False)
        )

    def _infer_managed_links(self) -> set[tuple[str, str]]:
        inferred: set[tuple[str, str]] = set()
        for consumer in CONSUMERS:
            root = self.config.consumer_root(consumer)
            if not root.is_dir():
                continue
            inferred.update(
                (consumer, entry.name)
                for entry in root.iterdir()
                if self._is_source_managed_link(entry)
            )
        return inferred

    def _discover_migratable_copies(self) -> set[tuple[str, str]]:
        """Identify Claude copies whose entrypoint matches grouped Agents."""
        copies: set[tuple[str, str]] = set()
        agents_root = self.config.consumer_root("agents")
        claude_root = self.config.consumer_root("claude")
        for category in CATEGORIES:
            group = agents_root / category
            if not group.is_dir() or group.is_symlink():
                continue
            for entry in group.iterdir():
                claude_copy = claude_root / entry.name
                agents_skill_md = entry / "SKILL.md"
                claude_skill_md = claude_copy / "SKILL.md"
                if (
                    entry.name in self.skills
                    and agents_skill_md.is_file()
                    and claude_skill_md.is_file()
                    and filecmp.cmp(
                        agents_skill_md,
                        claude_skill_md,
                        shallow=False,
                    )
                ):
                    copies.add(("claude", entry.name))
        return copies

    def _plan_grouped_agents(self, actions: list[Action]) -> None:
        if not self.migrate:
            return

        root = self.config.consumer_root("agents")
        for category in CATEGORIES:
            group = root / category
            if not group.is_dir() or group.is_symlink():
                continue

            for entry in sorted(group.iterdir()):
                name = entry.name
                if (
                    name == README_FILENAME
                    or name in self.skills
                    or name in GROUPED_LEGACY_SKILLS
                ):
                    continue

                target = root / name
                if target.exists() or target.is_symlink():
                    raise SyncError(
                        f"cannot flatten custom skill {name!r}; "
                        f"target already exists: {target}"
                    )
                actions.append(
                    Action(
                        kind=ActionKind.MOVE,
                        label=f"preserve custom agents/{name}",
                        target=entry,
                        destination=target,
                        migration=True,
                    )
                )

            actions.append(
                Action(
                    kind=ActionKind.MOVE,
                    label=f"archive Agents category {category}",
                    target=group,
                    destination=(
                        self.backup_dir / "removed" / "agents" / f"grouped-{category}"
                    ),
                    migration=True,
                )
            )

    def _plan_legacy_entries(self, actions: list[Action]) -> None:
        if not self.migrate:
            return

        for consumer, name in sorted(LEGACY_ENTRIES):
            target = self.config.consumer_root(consumer) / name
            if not target.exists() and not target.is_symlink():
                continue
            actions.append(
                Action(
                    kind=ActionKind.MOVE,
                    label=f"archive legacy {consumer}/{name}",
                    target=target,
                    destination=(
                        self.backup_dir
                        / "removed"
                        / consumer
                        / f"legacy-{name}"
                    ),
                    migration=True,
                )
            )

    def _plan_link(
        self,
        actions: list[Action],
        consumer: str,
        name: str,
        source: Path,
    ) -> None:
        target = self.config.consumer_root(consumer) / name
        key = (consumer, name)

        if target.is_symlink():
            if resolved_link(target) == source.resolve():
                return
            if (
                key not in self.previously_managed
                and not self._is_source_managed_link(target)
            ):
                raise SyncError(f"unmanaged symlink collision: {target}")
            actions.append(
                Action(
                    kind=ActionKind.UNLINK,
                    label=f"replace stale link {consumer}/{name}",
                    target=target,
                )
            )
        elif target.exists():
            if not self.migrate or key not in self.migratable_copies:
                raise SyncError(
                    f"unverified real path collision: {target}; "
                    "--migrate only accepts copies corroborated by "
                    "the grouped Agents layout"
                )
            actions.append(
                Action(
                    kind=ActionKind.MOVE,
                    label=f"archive copied {consumer}/{name}",
                    target=target,
                    destination=(
                        self.backup_dir
                        / "removed"
                        / consumer
                        / f"copied-{name}"
                    ),
                    migration=True,
                )
            )

        actions.append(
            Action(
                kind=ActionKind.LINK,
                label=f"link {consumer}/{name}",
                target=target,
                source=source,
            )
        )

    def _plan_stale_links(self, actions: list[Action]) -> None:
        for consumer, name in sorted(
            self.previously_managed - self.desired.keys()
        ):
            target = self.config.consumer_root(consumer) / name
            if not target.exists() and not target.is_symlink():
                continue
            if not self._is_source_managed_link(target):
                raise SyncError(
                    "stale managed path was replaced outside the synchronizer: "
                    f"{target}"
                )
            actions.append(
                Action(
                    kind=ActionKind.UNLINK,
                    label=f"unlink stale {consumer}/{name}",
                    target=target,
                )
            )

    def plan(self) -> Plan:
        actions: list[Action] = []
        self._plan_grouped_agents(actions)
        self._plan_legacy_entries(actions)
        for (consumer, name), source in sorted(self.desired.items()):
            self._plan_link(actions, consumer, name, source)
        self._plan_stale_links(actions)
        return Plan(
            actions=tuple(actions),
            desired_keys=tuple(sorted(self.desired)),
            backup_dir=self.backup_dir,
        )


def print_plan(plan: Plan) -> None:
    if not plan.actions:
        print("skills: already up to date")
        return
    for action in plan.actions:
        print(f"{action.kind.value}: {action.label}")
    if plan.needs_migration_backup:
        print(f"backup: {plan.backup_dir}")


def snapshot_consumers(config: Config, backup_dir: Path) -> None:
    for consumer in CONSUMERS:
        source = config.consumer_root(consumer)
        if not source.is_dir():
            continue
        destination = backup_dir / "snapshot" / consumer
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, destination, symlinks=True)


def execute_plan(config: Config, plan: Plan) -> None:
    if plan.needs_migration_backup:
        snapshot_consumers(config, plan.backup_dir)

    for action in plan.actions:
        if action.kind is ActionKind.MOVE:
            assert action.destination is not None
            action.destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(action.target), str(action.destination))
        elif action.kind is ActionKind.UNLINK:
            action.target.unlink()
        elif action.kind is ActionKind.LINK:
            assert action.source is not None
            action.target.parent.mkdir(parents=True, exist_ok=True)
            relative = os.path.relpath(action.source, action.target.parent)
            action.target.symlink_to(relative, target_is_directory=action.source.is_dir())
        else:
            raise SyncError(f"unknown action kind: {action.kind}")

    write_manifest(config, plan.desired_keys)


def write_manifest(
    config: Config, desired_keys: Iterable[tuple[str, str]]
) -> None:
    config.state_root.mkdir(parents=True, exist_ok=True)
    manifest = config.state_root / "managed-links.json"
    temporary = manifest.with_suffix(".tmp")
    payload: ManifestPayload = {
        "version": MANIFEST_VERSION,
        "links": [
            {"consumer": consumer, "name": name}
            for consumer, name in desired_keys
        ],
    }
    temporary.write_text(
        json.dumps(payload, indent=2, sort_keys=True) + "\n",
        encoding="utf-8",
    )
    temporary.replace(manifest)


def require_clean_checkout(config: Config) -> None:
    status = subprocess.run(
        ["git", "-C", str(config.skills_repo), "status", "--porcelain"],
        check=True,
        text=True,
        capture_output=True,
    )
    if status.stdout:
        raise SyncError("skills checkout has local changes; refusing to pull")


def pull_latest(config: Config) -> None:
    print(f"pull: {config.skills_repo}")
    subprocess.run(
        ["git", "-C", str(config.skills_repo), "pull", "--ff-only"],
        check=True,
    )


def run_stow(config: Config, operation: str) -> None:
    action = "unstow" if operation == "-D" else "stow"
    for consumer in CONSUMERS:
        print(f"{action}: {consumer} (--no-folding)")
        subprocess.run(
            [
                "stow",
                f"--dir={config.dotfiles_root}",
                f"--target={Path.home()}",
                operation,
                "--no-folding",
                consumer,
            ],
            check=True,
        )


def unstow(config: Config) -> None:
    """Remove live links while every pre-reconciliation source still exists."""
    run_stow(config, "-D")


def restow(config: Config) -> None:
    run_stow(config, "-R")


@dataclass
class StowGuard:
    config: Config
    enabled: bool
    unstowed: bool = False

    def ensure_unstowed(self) -> None:
        if not self.enabled or self.unstowed:
            return
        unstow(self.config)
        self.unstowed = True

    def restore(self) -> None:
        if not self.enabled:
            return
        restow(self.config)
        self.unstowed = False

    def recover(self) -> None:
        if not self.unstowed:
            return
        try:
            self.restore()
        except (subprocess.CalledProcessError, OSError) as error:
            print(
                f"error: failed to restore Stow layout: {error}",
                file=sys.stderr,
            )


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update and reconcile Matt Pocock skills."
    )
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument(
        "--dry-run", action="store_true", help="print changes without applying them"
    )
    mode.add_argument(
        "--check", action="store_true", help="exit non-zero when changes are needed"
    )
    parser.add_argument(
        "--migrate",
        action="store_true",
        help="back up and replace copied or grouped fork skills",
    )
    parser.add_argument("--no-pull", action="store_true")
    parser.add_argument("--no-stow", action="store_true")
    return parser.parse_args(argv)


def config_from_environment() -> Config:
    dotfiles_root = Path(
        os.environ.get("DOTFILES_ROOT", Path(__file__).resolve().parent.parent)
    ).resolve()
    skills_repo = Path(
        os.environ.get(
            "SKILLS_REPO",
            Path.home() / "workspace" / "personal" / "skills",
        )
    ).resolve()
    state_root = Path(
        os.environ.get("SKILL_SYNC_STATE_ROOT", dotfiles_root / ".skill-sync")
    ).resolve()
    backup_root = Path(
        os.environ.get(
            "SKILL_SYNC_BACKUP_ROOT",
            Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
            / "dotfiles-skills"
            / "backups",
        )
    ).resolve()
    return Config(
        dotfiles_root=dotfiles_root,
        skills_repo=skills_repo,
        state_root=state_root,
        backup_root=backup_root,
    )


def update_checkout(
    config: Config,
    args: argparse.Namespace,
    stow_guard: StowGuard,
) -> None:
    if args.no_pull or args.dry_run or args.check:
        return
    require_clean_checkout(config)
    stow_guard.ensure_unstowed()
    pull_latest(config)


def read_only_result(args: argparse.Namespace, plan: Plan) -> int | None:
    if args.dry_run:
        return 0
    if args.check:
        return 1 if plan.actions else 0
    return None


def apply_sync(config: Config, plan: Plan, stow_guard: StowGuard) -> None:
    if plan.actions:
        stow_guard.ensure_unstowed()
    execute_plan(config, plan)
    stow_guard.restore()
    print("skills: synchronized")


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    config = config_from_environment()
    stow_guard = StowGuard(config, enabled=not args.no_stow)
    try:
        update_checkout(config, args, stow_guard)
        plan = Reconciler(config, migrate=args.migrate).plan()
        print_plan(plan)
        result = read_only_result(args, plan)
        if result is not None:
            return result
        apply_sync(config, plan, stow_guard)
        return 0
    except (SyncError, subprocess.CalledProcessError, OSError) as error:
        stow_guard.recover()
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
