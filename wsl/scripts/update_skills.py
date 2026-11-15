#!/usr/bin/env python3
"""Synchronize a read-only skills checkout into dotfiles Stow packages.

Disk discovery produces an immutable DiskSnapshot; plan() makes only pure
decisions. SyncSession supplies the backup directory and owns execution/recovery.
"""

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
from typing import Iterable, Protocol, TypedDict


@dataclass(frozen=True)
class Consumer:
    """One agent tool's Stow package and skill layout."""

    name: str
    skills_dir: Path

    def package_root(self, dotfiles_root: Path) -> Path:
        return dotfiles_root / self.name / self.skills_dir

    def live_root(self, home: Path) -> Path:
        return home / self.skills_dir


# The Stow packages; shared/skills/skills.json must declare the same consumers and targets.
CONSUMERS: tuple[Consumer, ...] = (
    Consumer("agents", Path(".agents/skills")),
    Consumer("claude", Path(".claude/skills")),
)
SHARED_MANIFEST_FILENAME = "skills.json"
SHARED_MANIFEST_VERSION = 2
README_FILENAME = "README.md"
LEGACY_ENTRIES = frozenset(
    {
        ("claude", "to-issues"),
        ("claude", "to-prd"),
    }
)
GROUPED_LEGACY_SKILLS = frozenset({"to-issues", "to-prd", "teach copy"})
MANIFEST_VERSION = 1
# Upstream checkouts that personal skills link into. They are pulled alongside
# the skills checkout but never reconciled; dotfiles tracks their links.
EXTRA_CHECKOUTS = {
    "humanizer": "https://github.com/blader/humanizer.git",
}


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
    extra_checkouts: dict[Path, str]
    shared_root: Path

    @property
    def skills_root(self) -> Path:
        return self.skills_repo / "skills"



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


@dataclass(frozen=True)
class SourceSkill:
    name: str
    path: Path
    resolved_path: Path


@dataclass(frozen=True)
class ConsumerPath:
    path: Path
    is_symlink: bool = False
    resolved_target: Path | None = None
    exists: bool = False
    is_dir: bool = False


@dataclass(frozen=True)
class DiskSnapshot:
    """Immutable disk facts used to plan managed links for each Consumer."""

    skills: tuple[SourceSkill, ...]
    catalogs: tuple[SourceSkill, ...]
    # Skills from shared/skills/skills.json, each paired with its consumer.
    manifest_skills: tuple[tuple[str, SourceSkill], ...]
    categories: tuple[str, ...]
    resolved_skills_root: Path
    resolved_shared_root: Path

    def is_managed_target(self, target: Path | None) -> bool:
        """A link into the skills checkout or shared/skills/ is the sync's to replace."""
        return target is not None and (
            is_within(target, self.resolved_skills_root)
            or is_within(target, self.resolved_shared_root)
        )
    consumer_roots: tuple[tuple[str, Path], ...]
    manifest_entries: frozenset[tuple[str, str]]
    inferred_managed_links: frozenset[tuple[str, str]]
    migratable_copies: frozenset[tuple[str, str]]
    consumer_paths: tuple[ConsumerPath, ...]
    grouped_entries: tuple[tuple[str, tuple[Path, ...]], ...]


def read_shared_manifest(
    shared_root: Path,
) -> tuple[tuple[str, ...], tuple[tuple[str, SourceSkill], ...]]:
    """Return the categories and per-consumer skills shared/skills/skills.json declares.

    A skill's source is one path for every consumer or a map of consumer to
    path; a map that skips a consumer must say why in "reason".
    """
    manifest = shared_root / SHARED_MANIFEST_FILENAME
    consumers = [consumer.name for consumer in CONSUMERS]
    try:
        payload = json.loads(manifest.read_text(encoding="utf-8"))
        if payload.get("version") != SHARED_MANIFEST_VERSION:
            raise ValueError("unsupported manifest version")
        categories = tuple(payload["repository"]["categories"])
        declared = {
            name: Path(consumer["target"]) for name, consumer in payload["consumers"].items()
        }
        expected = {consumer.name: consumer.skills_dir for consumer in CONSUMERS}
        if declared != expected:
            raise ValueError(f"consumers {declared} do not match {expected}")
        entries = payload["skills"]
    except (OSError, ValueError, KeyError, TypeError) as error:
        raise SyncError(f"invalid shared manifest {manifest}: {error}") from error

    shared: list[tuple[str, SourceSkill]] = []
    for entry in entries:
        name = entry["name"]
        source = entry["source"]
        sources = (
            {consumer: source for consumer in consumers}
            if isinstance(source, str)
            else dict(source)
        )
        for consumer in sources:
            if consumer not in consumers:
                raise SyncError(f"skill {name!r} names unknown consumer {consumer!r}")
        for consumer in consumers:
            if consumer not in sources and not entry.get("reason"):
                raise SyncError(f"skill {name!r} skips {consumer} without a reason")
        for consumer, relative in sorted(sources.items()):
            path = shared_root / relative
            if not (path / "SKILL.md").is_file():
                raise SyncError(f"skill {name!r} has no SKILL.md in {path}")
            shared.append((consumer, SourceSkill(name, path, path.resolve())))
    return categories, tuple(shared)


def read_snapshot(config: Config) -> DiskSnapshot:
    """Read source skills, Managed links, and corroborated migration copies once."""
    if not config.skills_root.is_dir():
        raise SyncError(f"skills checkout not found at {config.skills_repo}")
    categories, manifest_skills = read_shared_manifest(config.shared_root)

    skills: dict[str, SourceSkill] = {}
    catalogs: list[SourceSkill] = []
    for category in categories:
        category_root = config.skills_root / category
        catalog = category_root / README_FILENAME
        if not catalog.is_file():
            raise SyncError(f"missing category catalog: {catalog}")
        catalogs.append(
            SourceSkill(f"{category.upper()}.md", catalog, catalog.resolve())
        )
        for skill_md in sorted(category_root.glob("*/SKILL.md")):
            name = skill_md.parent.name
            previous = skills.get(name)
            if previous is not None:
                raise SyncError(
                    f"duplicate skill name {name!r}: {previous.path} and {skill_md.parent}"
                )
            skills[name] = SourceSkill(name, skill_md.parent, skill_md.parent.resolve())
    for _, source in manifest_skills:
        if source.name in skills:
            raise SyncError(
                f"manifest skill {source.name!r} collides with an upstream skill"
            )

    links_manifest = config.state_root / "managed-links.json"
    manifest_entries: set[tuple[str, str]] = set()
    if links_manifest.exists():
        try:
            payload = json.loads(links_manifest.read_text(encoding="utf-8"))
            if payload.get("version") != MANIFEST_VERSION:
                raise ValueError("unsupported manifest version")
            manifest_entries = {
                (entry["consumer"], entry["name"])
                for entry in payload.get("links", [])
            }
        except (OSError, ValueError, KeyError, TypeError) as error:
            raise SyncError(f"invalid sync manifest {links_manifest}: {error}") from error

    paths: dict[Path, ConsumerPath] = {}

    def inspect(path: Path) -> ConsumerPath:
        if path not in paths:
            symlink = path.is_symlink()
            paths[path] = ConsumerPath(
                path=path,
                is_symlink=symlink,
                resolved_target=resolved_link(path) if symlink else None,
                exists=path.exists(),
                is_dir=path.is_dir(),
            )
        return paths[path]

    resolved_skills_root = config.skills_root.resolve(strict=False)
    resolved_shared_root = config.shared_root.resolve(strict=False)
    consumer_roots = tuple(
        (consumer.name, consumer.package_root(config.dotfiles_root))
        for consumer in CONSUMERS
    )
    roots = dict(consumer_roots)
    inferred: set[tuple[str, str]] = set()
    for consumer, root in consumer_roots:
        if inspect(root).is_dir:
            for entry in root.iterdir():
                state = inspect(entry)
                if state.is_symlink and any(
                    is_within(state.resolved_target, managed)
                    for managed in (resolved_skills_root, resolved_shared_root)
                ):
                    inferred.add((consumer, entry.name))
        for source in (*skills.values(), *catalogs):
            inspect(root / source.name)
    for consumer, source in manifest_skills:
        inspect(roots[consumer] / source.name)

    for consumer, name in manifest_entries | LEGACY_ENTRIES:
        inspect(roots[consumer] / name)

    grouped_entries: list[tuple[str, tuple[Path, ...]]] = []
    migratable_copies: set[tuple[str, str]] = set()
    agents_root = roots["agents"]
    claude_root = roots["claude"]
    for category in categories:
        group = agents_root / category
        state = inspect(group)
        if not state.is_dir or state.is_symlink:
            continue
        entries = tuple(sorted(group.iterdir()))
        grouped_entries.append((category, entries))
        for entry in entries:
            inspect(entry)
            inspect(agents_root / entry.name)
            agents_skill_md = entry / "SKILL.md"
            claude_skill_md = claude_root / entry.name / "SKILL.md"
            if (
                entry.name in skills
                and agents_skill_md.is_file()
                and claude_skill_md.is_file()
                and filecmp.cmp(agents_skill_md, claude_skill_md, shallow=False)
            ):
                migratable_copies.add(("claude", entry.name))

    return DiskSnapshot(
        skills=tuple(skills.values()),
        catalogs=tuple(catalogs),
        manifest_skills=manifest_skills,
        categories=categories,
        resolved_skills_root=resolved_skills_root,
        resolved_shared_root=resolved_shared_root,
        consumer_roots=consumer_roots,
        manifest_entries=frozenset(manifest_entries),
        inferred_managed_links=frozenset(inferred),
        migratable_copies=frozenset(migratable_copies),
        consumer_paths=tuple(paths.values()),
        grouped_entries=tuple(grouped_entries),
    )


def plan(snapshot: DiskSnapshot, *, migrate: bool, backup_dir: Path) -> Plan:
    """Choose actions solely from captured disk facts and explicit run inputs."""
    roots = dict(snapshot.consumer_roots)
    paths = {state.path: state for state in snapshot.consumer_paths}
    skills = {source.name for source in snapshot.skills}
    desired = {
        (consumer, source.name): source
        for consumer in roots
        for source in (*snapshot.skills, *snapshot.catalogs)
    }
    desired.update(
        ((consumer, source.name), source) for consumer, source in snapshot.manifest_skills
    )
    previously_managed = snapshot.manifest_entries | snapshot.inferred_managed_links
    actions: list[Action] = []

    def source_managed(state: ConsumerPath) -> bool:
        return state.is_symlink and snapshot.is_managed_target(state.resolved_target)

    if migrate:
        root = roots["agents"]
        for category, entries in snapshot.grouped_entries:
            for entry in entries:
                name = entry.name
                if (
                    name == README_FILENAME
                    or name in skills
                    or name in GROUPED_LEGACY_SKILLS
                ):
                    continue
                target = root / name
                state = paths[target]
                if state.exists or state.is_symlink:
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
                    target=root / category,
                    destination=backup_dir / "removed" / "agents" / f"grouped-{category}",
                    migration=True,
                )
            )

        for consumer, name in sorted(LEGACY_ENTRIES):
            target = roots[consumer] / name
            state = paths[target]
            if state.exists or state.is_symlink:
                actions.append(
                    Action(
                        kind=ActionKind.MOVE,
                        label=f"archive legacy {consumer}/{name}",
                        target=target,
                        destination=backup_dir / "removed" / consumer / f"legacy-{name}",
                        migration=True,
                    )
                )

    for (consumer, name), source in sorted(desired.items()):
        target = roots[consumer] / name
        state = paths[target]
        if state.is_symlink:
            if state.resolved_target == source.resolved_path:
                continue
            if (consumer, name) not in previously_managed and not source_managed(state):
                raise SyncError(f"unmanaged symlink collision: {target}")
            actions.append(
                Action(
                    kind=ActionKind.UNLINK,
                    label=f"replace stale link {consumer}/{name}",
                    target=target,
                )
            )
        elif state.exists:
            if not migrate or (consumer, name) not in snapshot.migratable_copies:
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
                    destination=backup_dir / "removed" / consumer / f"copied-{name}",
                    migration=True,
                )
            )
        actions.append(
            Action(
                kind=ActionKind.LINK,
                label=f"link {consumer}/{name}",
                target=target,
                source=source.path,
            )
        )

    for consumer, name in sorted(previously_managed - desired.keys()):
        target = roots[consumer] / name
        state = paths[target]
        if not state.exists and not state.is_symlink:
            continue
        if not source_managed(state):
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
    reject_unknown_real_paths(snapshot, desired.keys() | previously_managed)
    return Plan(
        actions=tuple(actions),
        desired_keys=tuple(sorted(desired)),
        backup_dir=backup_dir,
    )


def reject_unknown_real_paths(
    snapshot: DiskSnapshot, owned: Iterable[tuple[str, str]]
) -> None:
    """Reject real entries the sync cannot retire, such as stale skill copies.

    The package README and paths that planning already handles (desired links,
    stale managed links, the grouped Agents layout) are the only real entries a
    consumer package may hold; every skill is a link.
    """
    owned = frozenset(owned)
    grouped = {entry.name for _, entries in snapshot.grouped_entries for entry in entries}
    roots = {root: consumer for consumer, root in snapshot.consumer_roots}
    for state in snapshot.consumer_paths:
        consumer = roots.get(state.path.parent)
        name = state.path.name
        if (
            consumer is None
            or state.is_symlink
            or not state.exists
            or (consumer, name) in owned
            or name == README_FILENAME
            or name in snapshot.categories
            or name in grouped
        ):
            continue
        raise SyncError(
            f"unknown real skill path: {state.path}; declare the skill in "
            "shared/skills/skills.json and remove this copy"
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
        source = consumer.package_root(config.dotfiles_root)
        if not source.is_dir():
            continue
        destination = backup_dir / "snapshot" / consumer.name
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


class GitAdapter(Protocol):
    def require_checkout(self, repo: Path) -> None: ...

    def require_clean(self, repo: Path) -> None: ...

    def pull(self, repo: Path) -> None: ...


class StowAdapter(Protocol):
    def unstow(self) -> None: ...

    def restow(self) -> None: ...


@dataclass
class SubprocessGitAdapter:
    checkout_urls: dict[Path, str]

    def require_checkout(self, repo: Path) -> None:
        if not (repo / ".git").exists():
            url = self.checkout_urls[repo]
            raise SyncError(
                f"checkout not found at {repo}; clone it with: git clone {url} {repo}"
            )

    def require_clean(self, repo: Path) -> None:
        status = subprocess.run(
            ["git", "-C", str(repo), "status", "--porcelain"],
            check=True,
            text=True,
            capture_output=True,
        )
        if status.stdout:
            raise SyncError(f"checkout {repo} has local changes; refusing to pull")

    def pull(self, repo: Path) -> None:
        print(f"pull: {repo}")
        subprocess.run(
            ["git", "-C", str(repo), "pull", "--ff-only"],
            check=True,
        )


def run_stow(config: Config, operation: str, *, no_folding: bool) -> None:
    action = "unstow" if operation == "-D" else "stow"
    layout = " (--no-folding)" if no_folding else ""
    for consumer in CONSUMERS:
        print(f"{action}: {consumer.name}{layout}")
        command = [
            "stow",
            f"--dir={config.dotfiles_root}",
            f"--target={Path.home()}",
            operation,
        ]
        if no_folding:
            command.append("--no-folding")
        command.append(consumer.name)
        subprocess.run(command, check=True)


def prepare_live_skill_roots(config: Config) -> None:
    """Keep shared roots real and let Stow fold each managed skill directory."""
    for consumer in CONSUMERS:
        live_root = consumer.live_root(Path.home())
        if live_root.is_symlink():
            raise SyncError(
                f"skill root must be a real directory before restow: {live_root}"
            )
        live_root.mkdir(parents=True, exist_ok=True)

        package_root = consumer.package_root(config.dotfiles_root)
        if not package_root.is_dir():
            continue
        for source in package_root.iterdir():
            target = live_root / source.name
            if (
                source.is_dir()
                and not source.is_symlink()
                and target.is_dir()
                and not target.is_symlink()
                and next(target.iterdir(), None) is None
            ):
                target.rmdir()


@dataclass
class SubprocessStowAdapter:
    config: Config

    def unstow(self) -> None:
        """Unlink consumers while pre-reconciliation sources still exist."""
        run_stow(self.config, "-D", no_folding=True)

    def restow(self) -> None:
        # Remove the legacy file-by-file layout even when this Sync session did
        # not need to unlink consumers before reconciliation.
        self.unstow()
        prepare_live_skill_roots(self.config)
        run_stow(self.config, "-R", no_folding=False)


@dataclass
class SyncSession:
    """Own ordering and recovery for one reconciliation of consumer links."""

    config: Config
    git: GitAdapter
    stow: StowAdapter
    migrate: bool = False
    no_pull: bool = False
    no_stow: bool = False
    dry_run: bool = False
    check: bool = False
    backup_dir: Path | None = None

    def run(self) -> int:
        consumers_unlinked = False
        try:
            try:
                if not (self.no_pull or self.dry_run or self.check):
                    for repo in self.config.extra_checkouts:
                        self.git.require_checkout(repo)
                    # Clean checkouts are a Precondition: a dirty one pulls nothing.
                    for repo in (self.config.skills_repo, *self.config.extra_checkouts):
                        self.git.require_clean(repo)
                    for repo in self.config.extra_checkouts:
                        self.git.pull(repo)
                    if not self.no_stow:
                        # Unstow can fail after unlinking only some consumers.
                        consumers_unlinked = True
                        self.stow.unstow()
                    self.git.pull(self.config.skills_repo)

                backup_dir = self.backup_dir
                if backup_dir is None:
                    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S-%f")
                    backup_dir = self.config.backup_root / timestamp
                sync_plan = plan(
                    read_snapshot(self.config),
                    migrate=self.migrate,
                    backup_dir=backup_dir,
                )
                print_plan(sync_plan)
                if self.dry_run:
                    return 0
                if self.check:
                    return 1 if sync_plan.actions else 0

                if sync_plan.actions and not self.no_stow and not consumers_unlinked:
                    consumers_unlinked = True
                    self.stow.unstow()
                execute_plan(self.config, sync_plan)
                write_manifest(self.config, sync_plan.desired_keys)
                if not self.no_stow:
                    # Restow itself unlinks the legacy layout before rebuilding it.
                    consumers_unlinked = True
                    self.stow.restow()
                    consumers_unlinked = False
                print("skills: synchronized")
                return 0
            finally:
                if consumers_unlinked:
                    try:
                        self.stow.restow()
                    except BaseException as error:
                        # Recovery must never replace the original failure,
                        # including exceptions outside the CLI's handled errors.
                        print(
                            f"error: failed to restore Stow layout: {error}",
                            file=sys.stderr,
                        )
        except (SyncError, subprocess.CalledProcessError, OSError) as error:
            print(f"error: {error}", file=sys.stderr)
            return 2


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Update upstream skill checkouts and reconcile Matt Pocock skills."
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
    extra_root = Path(
        os.environ.get(
            "EXTRA_CHECKOUTS_ROOT", Path.home() / "workspace" / "personal"
        )
    ).resolve()
    shared_root = Path(
        os.environ.get(
            "SHARED_SKILLS_ROOT", dotfiles_root.parent / "shared" / "skills"
        )
    ).resolve()
    return Config(
        shared_root=shared_root,
        dotfiles_root=dotfiles_root,
        skills_repo=skills_repo,
        state_root=state_root,
        backup_root=backup_root,
        extra_checkouts={
            extra_root / name: url for name, url in EXTRA_CHECKOUTS.items()
        },
    )


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])
    config = config_from_environment()
    return SyncSession(
        config,
        SubprocessGitAdapter(config.extra_checkouts),
        SubprocessStowAdapter(config),
        **vars(args),
    ).run()


if __name__ == "__main__":
    raise SystemExit(main())
