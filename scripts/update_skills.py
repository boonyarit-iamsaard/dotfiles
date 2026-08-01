#!/usr/bin/env python3
"""Synchronize Matt Pocock skills into local Agent Skills consumers."""

from __future__ import annotations

import argparse
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
MANIFEST_VERSION = 1
LOCAL_SKILLS = frozenset({"commit-message", "typescript-object-composition"})
LEGACY_MATT_SKILLS = frozenset({"diagnose", "to-issues", "to-prd", "zoom-out"})
CONSUMER_LAYOUTS = {
    "agents": ("agents", ".agents"),
    "claude": ("claude", ".claude"),
}


class SyncError(RuntimeError):
    """A safe synchronization plan cannot be produced or executed."""


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
    home: Path

    @property
    def skills_root(self) -> Path:
        return self.skills_repo / "skills"

    def package_root(self, consumer: str) -> Path:
        try:
            package, home_directory = CONSUMER_LAYOUTS[consumer]
        except KeyError as error:
            raise ValueError(f"unknown consumer: {consumer}") from error
        return self.dotfiles_root / package / home_directory / "skills"

    def live_root(self, consumer: str) -> Path:
        try:
            _, home_directory = CONSUMER_LAYOUTS[consumer]
        except KeyError as error:
            raise ValueError(f"unknown consumer: {consumer}") from error
        return self.home / home_directory / "skills"


@dataclass(frozen=True)
class Action:
    kind: ActionKind
    consumer: str
    name: str
    target: Path
    source: Path | None = None
    destination: Path | None = None


@dataclass(frozen=True)
class Plan:
    actions: tuple[Action, ...]
    desired_keys: tuple[tuple[str, str], ...]
    backup_dir: Path

    @property
    def is_migration(self) -> bool:
        return any(action.kind is ActionKind.MOVE for action in self.actions)


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
        self.previously_managed = self._read_manifest() | self._infer_managed_links()
        self.migrating_keys: set[tuple[str, str]] = set()
        if self.migrate:
            (
                self.historical_blobs,
                self.historical_blobs_by_relative,
            ) = self._load_historical_blob_ids()
        else:
            self.historical_blobs = {}
            self.historical_blobs_by_relative = {}
        self.historical_path_cache: dict[tuple[str, str], set[str]] = {}
        timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
        self.backup_dir = self.config.backup_root / timestamp

    def _discover_skills(self) -> dict[str, Path]:
        if not self.config.skills_root.is_dir():
            raise SyncError(f"skills checkout not found at {self.config.skills_repo}")

        discovered: dict[str, Path] = {}
        for category in CATEGORIES:
            category_root = self.config.skills_root / category
            catalog = category_root / "README.md"
            if not catalog.is_file():
                raise SyncError(f"missing category catalog: {catalog}")
            for skill_md in sorted(category_root.glob("*/SKILL.md")):
                name = skill_md.parent.name
                previous = discovered.get(name)
                if previous is not None:
                    raise SyncError(
                        f"duplicate skill name {name!r}: "
                        f"{previous} and {skill_md.parent}"
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
                    self.config.skills_root / category / "README.md"
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
        return path.is_symlink() and is_within(
            resolved_link(path), self.config.skills_root.resolve(strict=False)
        )

    def _infer_managed_links(self) -> set[tuple[str, str]]:
        inferred: set[tuple[str, str]] = set()
        for consumer in CONSUMERS:
            root = self.config.live_root(consumer)
            if not root.is_dir():
                continue
            inferred.update(
                (consumer, entry.name)
                for entry in root.iterdir()
                if self._is_source_managed_link(entry)
            )
        return inferred

    def _plan_link(
        self,
        actions: list[Action],
        consumer: str,
        name: str,
        source: Path,
    ) -> None:
        target = self.config.live_root(consumer) / name
        key = (consumer, name)
        package_entry = self.config.package_root(consumer) / name
        if (
            self.migrate
            and key in self.migrating_keys
            and target.exists()
            and target.resolve() == package_entry.resolve()
        ):
            actions.append(Action(ActionKind.LINK, consumer, name, target, source))
            return
        if target.is_symlink():
            if resolved_link(target) == source.resolve():
                return
            if not self._is_source_managed_link(target):
                raise SyncError(f"unmanaged symlink collision: {target}")
            actions.append(Action(ActionKind.UNLINK, consumer, name, target))
        elif target.exists():
            raise SyncError(f"unmanaged real path collision: {target}")

        actions.append(Action(ActionKind.LINK, consumer, name, target, source))

    def _plan_stale_links(self, actions: list[Action]) -> None:
        for consumer, name in sorted(self.previously_managed - self.desired.keys()):
            target = self.config.live_root(consumer) / name
            if not target.exists() and not target.is_symlink():
                continue
            if not self._is_source_managed_link(target):
                raise SyncError(
                    "stale managed path was replaced outside the synchronizer: "
                    f"{target}"
                )
            actions.append(Action(ActionKind.UNLINK, consumer, name, target))

    def _load_historical_blob_ids(
        self,
    ) -> tuple[dict[tuple[str, str], set[str]], dict[str, set[str]]]:
        result = subprocess.run(
            [
                "git",
                "-C",
                str(self.config.skills_repo),
                "rev-list",
                "--objects",
                "--all",
            ],
            check=True,
            text=True,
            capture_output=True,
        )
        discovered: dict[tuple[str, str], set[str]] = {}
        by_relative: dict[str, set[str]] = {}
        for line in result.stdout.splitlines():
            parts = line.split(maxsplit=1)
            if len(parts) != 2:
                continue
            object_id, object_path = parts
            path_parts = Path(object_path).parts
            if len(path_parts) < 4 or path_parts[0] != "skills":
                continue
            name = path_parts[2]
            relative = Path(*path_parts[3:]).as_posix()
            discovered.setdefault((name, relative), set()).add(object_id)
            by_relative.setdefault(relative, set()).add(object_id)
        return discovered, by_relative

    def _historical_blob_ids(self, name: str, relative: Path) -> set[str]:
        key = (name, relative.as_posix())
        cached = self.historical_path_cache.get(key)
        if cached is not None:
            return cached

        discovered = set(self.historical_blobs.get(key, set()))
        for category in CATEGORIES:
            object_path = f"skills/{category}/{name}/{relative.as_posix()}"
            history = subprocess.run(
                [
                    "git",
                    "-C",
                    str(self.config.skills_repo),
                    "log",
                    "--all",
                    "--format=%H",
                    "--",
                    object_path,
                ],
                check=True,
                text=True,
                capture_output=True,
            )
            for commit in history.stdout.splitlines():
                blob = subprocess.run(
                    [
                        "git",
                        "-C",
                        str(self.config.skills_repo),
                        "rev-parse",
                        f"{commit}:{object_path}",
                    ],
                    check=False,
                    text=True,
                    capture_output=True,
                )
                if blob.returncode == 0:
                    discovered.add(blob.stdout.strip())
        self.historical_path_cache[key] = discovered
        return discovered

    def _is_verified_historical_copy(self, path: Path, name: str) -> bool:
        files = [entry for entry in path.rglob("*") if entry.is_file()]
        if not files or any(entry.is_symlink() for entry in files):
            return False
        for file_path in files:
            blob = subprocess.run(
                ["git", "hash-object", str(file_path)],
                check=True,
                text=True,
                capture_output=True,
            ).stdout.strip()
            relative = file_path.relative_to(path)
            accepted_blobs = set(self._historical_blob_ids(name, relative))
            if name in LEGACY_MATT_SKILLS:
                accepted_blobs.update(
                    self.historical_blobs_by_relative.get(relative.as_posix(), set())
                )
            if blob not in accepted_blobs:
                return False
        return True

    def _package_entries(self, consumer: str) -> list[Path]:
        root = self.config.package_root(consumer)
        return sorted(root.iterdir()) if root.is_dir() else []

    def _plan_package_entry(
        self,
        actions: list[Action],
        consumer: str,
        entry: Path,
        managed_names: set[str],
    ) -> None:
        name = entry.name
        if name in LOCAL_SKILLS or name not in managed_names:
            return
        if entry.is_symlink() or not entry.is_dir():
            raise SyncError(f"unverified Matt copy collision: {entry}")
        if not self._is_verified_historical_copy(entry, name):
            raise SyncError(f"unverified Matt copy collision: {entry}")
        actions.append(
            Action(
                ActionKind.MOVE,
                consumer,
                name,
                entry,
                destination=self.backup_dir / "removed" / consumer / name,
            )
        )
        self.migrating_keys.add((consumer, name))

    def _plan_package_migration(self, actions: list[Action]) -> None:
        if not self.migrate:
            return
        managed_names = set(self.skills) | set(LEGACY_MATT_SKILLS)
        for consumer in CONSUMERS:
            for entry in self._package_entries(consumer):
                self._plan_package_entry(
                    actions, consumer, entry, managed_names
                )

    def plan(self) -> Plan:
        actions: list[Action] = []
        self._plan_package_migration(actions)
        for (consumer, name), source in sorted(self.desired.items()):
            self._plan_link(actions, consumer, name, source)
        self._plan_stale_links(actions)
        return Plan(
            tuple(actions), tuple(sorted(self.desired)), self.backup_dir
        )


def print_plan(plan: Plan) -> None:
    if not plan.actions:
        print("skills: already up to date")
        return
    for action in plan.actions:
        print(f"{action.kind.value}: {action.consumer}/{action.name}")
    if plan.is_migration:
        print(f"backup: {plan.backup_dir}")


def write_manifest(config: Config, desired_keys: Iterable[tuple[str, str]]) -> None:
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
        json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8"
    )
    temporary.replace(manifest)


def snapshot_packages(config: Config, backup_dir: Path) -> None:
    for consumer in CONSUMERS:
        source = config.package_root(consumer)
        if not source.is_dir():
            continue
        destination = backup_dir / "snapshot" / consumer
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copytree(source, destination, symlinks=True)


def run_stow(config: Config, operation: str, *, no_folding: bool) -> None:
    for consumer in CONSUMERS:
        command = [
            "stow",
            f"--dir={config.dotfiles_root}",
            f"--target={config.home}",
            operation,
        ]
        if no_folding:
            command.append("--no-folding")
        command.append(consumer)
        subprocess.run(command, check=True)


def prepare_live_roots(config: Config) -> None:
    for consumer in CONSUMERS:
        live_root = config.live_root(consumer)
        if live_root.is_symlink():
            raise SyncError(f"skill root must be a real directory: {live_root}")
        live_root.mkdir(parents=True, exist_ok=True)


def remove_direct_source_links(config: Config) -> None:
    for consumer in CONSUMERS:
        root = config.live_root(consumer)
        if not root.is_dir():
            continue
        for entry in root.iterdir():
            if entry.is_symlink() and is_within(
                resolved_link(entry), config.skills_root.resolve(strict=False)
            ):
                entry.unlink()


def rollback_migration(
    config: Config, completed_moves: list[Action], *, use_stow: bool
) -> None:
    if use_stow:
        try:
            run_stow(config, "-D", no_folding=True)
        except (subprocess.CalledProcessError, OSError):
            pass
    remove_direct_source_links(config)
    for action in reversed(completed_moves):
        assert action.destination is not None
        if not action.destination.exists() or action.target.exists():
            continue
        action.target.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(action.destination), str(action.target))
    if use_stow:
        try:
            run_stow(config, "-R", no_folding=True)
        except (subprocess.CalledProcessError, OSError) as error:
            print(f"error: failed to restore Stow layout: {error}", file=sys.stderr)


def execute_non_move_actions(actions: Iterable[Action]) -> None:
    for action in actions:
        if action.kind is ActionKind.UNLINK:
            action.target.unlink()
        elif action.kind is ActionKind.LINK:
            assert action.source is not None
            action.target.parent.mkdir(parents=True, exist_ok=True)
            relative = os.path.relpath(action.source, action.target.parent)
            action.target.symlink_to(
                relative, target_is_directory=action.source.is_dir()
            )
        else:
            raise SyncError(f"unexpected action during link phase: {action.kind}")


def execute_plan(config: Config, plan: Plan, *, use_stow: bool) -> None:
    if not plan.is_migration:
        execute_non_move_actions(plan.actions)
        write_manifest(config, plan.desired_keys)
        return

    move_actions = [
        action for action in plan.actions if action.kind is ActionKind.MOVE
    ]
    link_actions = [
        action for action in plan.actions if action.kind is not ActionKind.MOVE
    ]
    completed_moves: list[Action] = []
    snapshot_packages(config, plan.backup_dir)
    try:
        if use_stow:
            run_stow(config, "-D", no_folding=True)
        for action in move_actions:
            assert action.destination is not None
            action.destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.move(str(action.target), str(action.destination))
            completed_moves.append(action)
        if use_stow:
            prepare_live_roots(config)
            run_stow(config, "-R", no_folding=False)
        execute_non_move_actions(link_actions)
        write_manifest(config, plan.desired_keys)
    except (SyncError, subprocess.CalledProcessError, OSError):
        rollback_migration(config, completed_moves, use_stow=use_stow)
        raise


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
        ["git", "-C", str(config.skills_repo), "pull", "--ff-only"], check=True
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
        help="archive verified copied Matt skills and convert the Stow layout",
    )
    parser.add_argument(
        "--no-pull", action="store_true", help="reconcile without updating the checkout"
    )
    parser.add_argument("--no-stow", action="store_true", help=argparse.SUPPRESS)
    return parser.parse_args(argv)


def config_from_environment() -> Config:
    dotfiles_root = Path(
        os.environ.get("DOTFILES_ROOT", Path(__file__).resolve().parent.parent)
    ).resolve()
    skills_repo = Path(
        os.environ.get(
            "SKILLS_REPO", Path.home() / "workspace" / "personal" / "skills"
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
        home=Path.home().resolve(),
    )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    config = config_from_environment()
    try:
        if not (args.no_pull or args.dry_run or args.check):
            require_clean_checkout(config)
            pull_latest(config)
        plan = Reconciler(config, migrate=args.migrate).plan()
        print_plan(plan)
        if args.dry_run:
            return 0
        if args.check:
            return 1 if plan.actions else 0
        execute_plan(config, plan, use_stow=not args.no_stow)
        print("skills: synchronized")
        return 0
    except (SyncError, subprocess.CalledProcessError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
