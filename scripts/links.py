#!/usr/bin/env python3
"""Check the Mac's managed links from $HOME into the checkout."""

from __future__ import annotations

import argparse
import os
import sys
from dataclasses import dataclass
from pathlib import Path


# Stow packages whose links scripts/update-skills owns.
STOW_PACKAGES = ("agents", "claude")


@dataclass(frozen=True)
class Link:
    target: str
    source: str


class ListError(Exception):
    pass


def read_list(list_file: Path) -> list[Link]:
    links = []
    seen = set()
    lines = list_file.read_text(encoding="utf-8").splitlines()
    for number, line in enumerate(lines, start=1):
        if not line.strip() or line.startswith("#"):
            continue
        fields = line.split("\t")
        where = f"{list_file.name}:{number}"
        if len(fields) != 2 or not all(fields):
            raise ListError(f"{where}: expected target<TAB>source")
        for field in fields:
            parts = Path(field).parts
            if Path(field).is_absolute() or ".." in parts:
                raise ListError(f"{where}: path must stay inside its root: {field}")
        target, source = fields
        if target in seen:
            raise ListError(f"{where}: duplicate target: {target}")
        seen.add(target)
        links.append(Link(target, source))
    return links


def resolve(path: Path) -> Path:
    """Resolve one link hop lexically, so broken links still have a source."""
    return Path(os.path.normpath(path.parent / os.readlink(path)))


def display(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix() if path.is_relative_to(root) else str(path)


def scanned_dirs(home: Path, links: list[Link]) -> list[Path]:
    """Every real directory from $HOME down to each declared link's parent.

    New links placed beside managed ones are caught; links in directories
    holding no managed link are not, which keeps the scan out of large trees.
    """
    dirs = {home}
    for link in links:
        for parent in (home / link.target).parents:
            if parent == home:
                break
            dirs.add(parent)
    return sorted(d for d in dirs if d.is_dir() and not d.is_symlink())


def unlisted(home: Path, root: Path, links: list[Link]) -> list[str]:
    declared = {home / link.target for link in links}
    stow_packages = [root / package for package in STOW_PACKAGES]
    problems = []
    for directory in scanned_dirs(home, links):
        for path in sorted(directory.iterdir()):
            if not path.is_symlink() or path in declared:
                continue
            source = resolve(path)
            if not source.is_relative_to(root):
                continue
            if any(source.is_relative_to(package) for package in stow_packages):
                continue
            target = path.relative_to(home).as_posix()
            problems.append(f"unlisted: {target} -> {display(source, root)}")
    return problems


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--create",
        action="store_true",
        help="create missing links; existing files and links are never replaced",
    )
    parser.add_argument("--home", type=Path, default=Path.home())
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="checkout holding the link sources and links.tsv",
    )
    return parser.parse_args(argv)


def main(argv: list[str]) -> int:
    args = parse_args(argv)
    home = args.home.absolute()
    root = args.root.absolute()

    try:
        links = read_list(root / "links.tsv")
    except (ListError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 2
    problems = []
    ok = 0
    for link in links:
        path = home / link.target
        if not (root / link.source).exists():
            problems.append(f"no-source: {link.target} -> {link.source}")
            continue
        if not path.is_symlink():
            if path.exists():
                problems.append(f"not-a-link: {link.target}")
            elif args.create:
                path.parent.mkdir(parents=True, exist_ok=True)
                path.symlink_to(os.path.relpath(root / link.source, path.parent))
                print(f"created: {link.target}")
                ok += 1
            else:
                problems.append(f"missing: {link.target}")
            continue
        resolved = resolve(path)
        if resolved != root / link.source:
            problems.append(f"wrong: {link.target} -> {display(resolved, root)}")
            continue
        ok += 1
    problems += unlisted(home, root, links)
    for problem in problems:
        print(problem)
    print(f"links: {ok} ok, {len(problems)} problems")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
