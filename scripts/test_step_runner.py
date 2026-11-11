#!/usr/bin/env python3
"""Maintenance integration tests using an isolated PATH and fake executables.

SKILLS_UPDATER is a normal executable override: production defaults to the updater
beside the resolved script, while these tests use a harmless fixture executable.
No real package manager, Docker daemon, or skill sync is reachable through PATH.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
RUNNER = ROOT / "scripts" / "lib" / "step-runner.zsh"
UPDATE = ROOT / "update-system" / "update-system.sh"
DOCKER = ROOT / "docker-cleanup" / "docker-cleanup.sh"
ZSH = shutil.which("zsh")

FAKE_EXECUTABLE = r'''
import json
import os
import sys
from pathlib import Path

name = Path(sys.argv[0]).name
arguments = sys.argv[1:]
with open(os.environ["CALL_LOG"], "a", encoding="utf-8") as calls:
    calls.write(json.dumps([name, *arguments]) + "\n")
command = " ".join([name, *arguments])
if command in json.loads(os.environ.get("FAIL_COMMANDS", "[]")):
    print("Error: fixture failure")
    print("Err: fixture failure", end="")
    sys.exit(17)
if name == "sudo":
    if arguments == ["-v"]:
        sys.exit(0)
    os.execvp(arguments[0], arguments)
if name == "docker" and arguments == ["ps", "-aq"]:
    print(os.environ.get("CONTAINER_IDS", ""), end="")
elif name == "probe-output":
    print("first\nError: highlighted\nErr: highlighted\nlast", end="")
else:
    print(command)
    if name == "composer" and arguments[:1] == ["global"]:
        print("COMPOSER_HOME=" + os.environ.get("COMPOSER_HOME", ""))
'''


@unittest.skipUnless(ZSH, "zsh is required")
class StepRunnerTest(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.fixture = Path(self.temporary.name)
        self.home = self.fixture / "home"
        self.bin = self.fixture / "bin"
        self.calls = self.fixture / "calls.jsonl"
        self.home.mkdir()
        self.bin.mkdir()
        self.make_executable("skills-updater")
        self.environment = os.environ.copy()
        for variable in ("COMPOSER_HOME", "DOTFILES_ROOT", "ENV", "BASH_ENV"):
            self.environment.pop(variable, None)
        self.environment.update(
            {
                "HOME": str(self.home),
                "ZDOTDIR": str(self.home),
                "PATH": str(self.bin),
                "NO_COLOR": "1",
                "CALL_LOG": str(self.calls),
                "FAIL_COMMANDS": "[]",
                "CONTAINER_IDS": "",
                "SDKMAN_DIR": str(self.home / ".sdkman"),
                "SKILLS_UPDATER": str(self.bin / "skills-updater"),
                "STEP_RUNNER": str(RUNNER),
            }
        )

    def make_executable(self, name: str) -> Path:
        executable = self.bin / name
        executable.write_text(
            f"#!{sys.executable}\n" + FAKE_EXECUTABLE, encoding="utf-8"
        )
        executable.chmod(0o755)
        return executable

    def install_update_tools(self) -> None:
        for name in ("sudo", "apt", "apt-get", "journalctl", "brew", "npm", "composer", "rm", "sdk-free"):
            self.make_executable(name)
        sdk_init = self.home / ".sdkman" / "bin" / "sdkman-init.sh"
        sdk_init.parent.mkdir(parents=True)
        sdk_init.write_text('sdk() { command sdk-free "$@"; }\n', encoding="utf-8")
        composer = self.home / ".config" / "composer"
        composer.mkdir(parents=True)
        (composer / "composer.json").write_text("{}\n", encoding="utf-8")
        npm_logs = self.home / ".npm" / "_logs"
        npm_logs.mkdir(parents=True)
        (npm_logs / "debug.log").write_text("fixture\n", encoding="utf-8")

    def fail_commands(self, *commands: str) -> None:
        self.environment["FAIL_COMMANDS"] = json.dumps(commands)

    def run_zsh(
        self, *arguments: str, expected_returncode: int = 0
    ) -> subprocess.CompletedProcess[str]:
        result = subprocess.run(
            [ZSH, "-f", *arguments],
            text=True,
            capture_output=True,
            env=self.environment,
            timeout=15,
        )
        self.assertEqual(
            expected_returncode,
            result.returncode,
            msg=f"stdout:\n{result.stdout}\nstderr:\n{result.stderr}",
        )
        self.assertEqual("", result.stderr)
        self.assertNotIn("\033", result.stdout)
        self.assertTrue(result.stdout.isascii(), result.stdout)
        return result

    def run_steps(
        self, body: str, expected_returncode: int = 0
    ) -> subprocess.CompletedProcess[str]:
        return self.run_zsh(
            "-c", 'source "$STEP_RUNNER"\n' + body,
            expected_returncode=expected_returncode,
        )

    def run_script(
        self, script: Path, expected_returncode: int = 0, linked: bool = False
    ) -> subprocess.CompletedProcess[str]:
        if linked:
            link = self.home / script.name
            link.symlink_to(script)
            script = link
        return self.run_zsh(str(script), expected_returncode=expected_returncode)

    def recorded_calls(self) -> list[list[str]]:
        if not self.calls.exists():
            return []
        return [json.loads(line) for line in self.calls.read_text().splitlines()]

    def test_error_failure_preserves_command_status_and_reports_summary(self) -> None:
        self.make_executable("probe")
        self.fail_commands("probe fail")
        result = self.run_steps(
            'step error "Critical update" probe fail\n'
            'step error "Later update" probe continue\nsteps_finish',
            expected_returncode=1,
        )
        self.assertIn("Step failed: Critical update (exit 17).", result.stdout)
        self.assertIn("1 succeeded, 1 failed (1 errors, 0 warnings), 0 skipped", result.stdout)
        self.assertIn("Failed steps: Critical update [error]", result.stdout)
        self.assertIn(["probe", "continue"], self.recorded_calls())

    def test_warning_failure_does_not_fail_the_script(self) -> None:
        self.make_executable("probe")
        self.fail_commands("probe fail")
        result = self.run_steps('step warn "Optional cleanup" probe fail\nsteps_finish')
        self.assertIn("0 succeeded, 1 failed (0 errors, 1 warnings), 0 skipped", result.stdout)
        self.assertIn("Failed steps: Optional cleanup [warn]", result.stdout)

    def test_step_group_stops_on_warning_and_runs_steps_outside_group(self) -> None:
        self.make_executable("probe")
        self.fail_commands("probe fail")
        result = self.run_steps(
            'group_begin "Ordered cleanup"\n'
            'step warn "First" probe fail\n'
            'step error "Second" probe skipped\n'
            'step warn "Third" probe also-skipped\n'
            'group_end\nstep error "Outside" probe outside\nsteps_finish'
        )
        self.assertEqual([["probe", "fail"], ["probe", "outside"]], self.recorded_calls())
        self.assertIn("Step skipped: Second (Step group: Ordered cleanup).", result.stdout)
        self.assertIn("Step skipped: Third (Step group: Ordered cleanup).", result.stdout)
        self.assertIn("1 succeeded, 1 failed (0 errors, 1 warnings), 2 skipped", result.stdout)

    def test_group_precondition_skips_group_without_aborting_script(self) -> None:
        self.make_executable("probe")
        self.fail_commands("probe fail")
        result = self.run_steps(
            'group_begin "Protected updates"\n'
            'precondition "Authentication" probe fail\n'
            'step error "Protected update" probe skipped\n'
            'group_end\nstep error "Independent update" probe outside\nsteps_finish',
            expected_returncode=1,
        )
        self.assertEqual([["probe", "fail"], ["probe", "outside"]], self.recorded_calls())
        self.assertIn("Step skipped: Protected update", result.stdout)
        self.assertIn("Failed steps: Authentication [error]", result.stdout)

    def test_standalone_precondition_aborts_and_prints_summary(self) -> None:
        self.make_executable("probe")
        self.fail_commands("probe fail")
        result = self.run_steps(
            'precondition "Required service" probe fail\n'
            'step error "Unreachable" probe unreachable\nsteps_finish',
            expected_returncode=1,
        )
        self.assertEqual([["probe", "fail"]], self.recorded_calls())
        self.assertIn("Failed steps: Required service [error]", result.stdout)

    def test_streaming_handles_both_error_patterns_and_unterminated_line(self) -> None:
        self.make_executable("probe-output")
        result = self.run_steps('step error "Output" probe-output\nsteps_finish')
        self.assertIn("[OUTPUT] first", result.stdout)
        self.assertIn("[BAD_OUTPUT] Error: highlighted", result.stdout)
        self.assertIn("[BAD_OUTPUT] Err: highlighted", result.stdout)
        self.assertIn("[OUTPUT] last\n", result.stdout)
        self.assertIn("1 succeeded, 0 failed", result.stdout)

    def test_update_runs_all_commands_through_stow_symlink(self) -> None:
        self.install_update_tools()
        result = self.run_script(UPDATE, linked=True)
        calls = self.recorded_calls()
        self.assertEqual(["sudo", "-v"], calls[0])
        for call in (
            ["apt", "update"], ["apt", "upgrade", "-y"],
            ["apt", "autoremove", "--purge", "-y"], ["apt-get", "clean"],
            ["journalctl", "--vacuum-time=14d"], ["brew", "upgrade"],
            ["brew", "cleanup", "--prune=all"], ["npm", "update", "-g"],
            ["composer", "self-update", "--stable", "--no-interaction"],
            ["composer", "global", "update", "--no-interaction"],
            ["sdk-free", "selfupdate"], ["sdk-free", "flush"], ["skills-updater"],
        ):
            self.assertIn(call, calls)
        self.assertIn(["rm", "-rf", "--", str(self.home / ".npm" / "_logs" / "debug.log")], calls)
        self.assertIn(f"COMPOSER_HOME={self.home / '.config' / 'composer'}", result.stdout)
        self.assertIn("0 failed", result.stdout)
        self.assertIn("[FINISHED] System update process finished.", result.stdout)

    def test_apt_failure_skips_remaining_group_but_not_other_tools(self) -> None:
        self.install_update_tools()
        self.fail_commands("apt update")
        result = self.run_script(UPDATE, expected_returncode=1)
        calls = self.recorded_calls()
        self.assertNotIn(["apt", "upgrade", "-y"], calls)
        self.assertNotIn(["apt", "autoremove", "--purge", "-y"], calls)
        self.assertNotIn(["apt-get", "clean"], calls)
        self.assertNotIn(["journalctl", "--vacuum-time=14d"], calls)
        self.assertIn(["brew", "upgrade"], calls)
        self.assertIn("Step skipped: Upgrading APT packages", result.stdout)
        self.assertIn("4 skipped", result.stdout)
        self.assertIn("Failed steps: Updating APT repositories [error]", result.stdout)
        self.assertNotIn("[FINISHED] System update process finished.", result.stdout)
        self.assertIn("[INFO] System update process finished.", result.stdout)

    def test_sudo_precondition_skips_apt_group_and_continues(self) -> None:
        self.install_update_tools()
        self.fail_commands("sudo -v")
        result = self.run_script(UPDATE, expected_returncode=1)
        calls = self.recorded_calls()
        self.assertEqual(["sudo", "-v"], calls[0])
        self.assertFalse(any(call[0] in {"apt", "apt-get", "journalctl"} for call in calls))
        self.assertIn(["brew", "upgrade"], calls)
        self.assertIn("Sudo authentication failed. Skipping APT update.", result.stdout)
        self.assertIn("5 skipped", result.stdout)

    def test_absent_update_tools_are_skipped_without_failure(self) -> None:
        result = self.run_script(UPDATE)
        for message in (
            "'apt' command not found. Skipping APT update.",
            "'brew' command not found. Skipping Homebrew update.",
            "'npm' command not found. Skipping npm update.",
            "'composer' command not found. Skipping Composer update.",
            "SDKMAN not found. Skipping SDKMAN update.",
        ):
            self.assertIn(message, result.stdout)
        self.assertEqual([["skills-updater"]], self.recorded_calls())
        self.assertIn("1 succeeded, 0 failed (0 errors, 0 warnings), 5 skipped", result.stdout)

    def test_update_warning_failures_leave_exit_status_successful(self) -> None:
        self.install_update_tools()
        self.fail_commands("journalctl --vacuum-time=14d", "sdk-free selfupdate", "skills-updater")
        result = self.run_script(UPDATE)
        self.assertIn("3 failed (0 errors, 3 warnings)", result.stdout)
        self.assertIn(["sdk-free", "flush"], self.recorded_calls())
        self.assertIn("Updating shared agent skills [warn]", result.stdout)

    def test_composer_unavailable_self_update_and_legacy_home(self) -> None:
        self.make_executable("composer")
        legacy_home = self.home / ".composer"
        legacy_home.mkdir()
        (legacy_home / "composer.json").write_text("{}\n", encoding="utf-8")
        self.fail_commands("composer self-update --help")
        result = self.run_script(UPDATE)
        self.assertIn("Composer self-update is unavailable.", result.stdout)
        self.assertNotIn(["composer", "self-update", "--stable", "--no-interaction"], self.recorded_calls())
        self.assertIn(["composer", "global", "update", "--no-interaction"], self.recorded_calls())
        self.assertIn(f"COMPOSER_HOME={legacy_home}", result.stdout)
        self.assertIn("0 failed", result.stdout)

    def test_docker_missing_aborts_before_any_cleanup(self) -> None:
        result = self.run_script(DOCKER, expected_returncode=1)
        self.assertIn("docker command could not be found. Please ensure it is installed.", result.stdout)
        self.assertIn("Failed steps: Docker on PATH [error]", result.stdout)
        self.assertEqual([], self.recorded_calls())

    def test_docker_info_failure_aborts_before_any_cleanup(self) -> None:
        self.make_executable("docker")
        self.fail_commands("docker info")
        result = self.run_script(DOCKER, expected_returncode=1)
        self.assertIn("Docker daemon is not running.", result.stdout)
        self.assertIn("Please start Docker", result.stdout)
        self.assertIn("Failed steps: Docker daemon availability [error]", result.stdout)
        self.assertEqual([["docker", "info"]], self.recorded_calls())

    def test_docker_removes_each_container_and_runs_prunes(self) -> None:
        self.make_executable("docker")
        self.environment["CONTAINER_IDS"] = "container-a\ncontainer-b\n"
        result = self.run_script(DOCKER, linked=True)
        self.assertEqual(
            [
                ["docker", "info"], ["docker", "ps", "-aq"],
                ["docker", "rm", "-f", "container-a", "container-b"],
                ["docker", "volume", "prune", "-af"],
                ["docker", "network", "prune", "-f"],
                ["docker", "builder", "prune", "-af"], ["docker", "system", "df"],
            ],
            self.recorded_calls(),
        )
        self.assertIn("0 failed", result.stdout)

    def test_docker_list_failure_aborts_before_pruning(self) -> None:
        self.make_executable("docker")
        self.fail_commands("docker ps -aq")
        result = self.run_script(DOCKER, expected_returncode=1)
        self.assertIn("Failed steps: Listing Docker containers [error]", result.stdout)
        self.assertEqual(
            [["docker", "info"], ["docker", "ps", "-aq"]], self.recorded_calls()
        )

    def test_docker_no_containers_warns_and_skips_removal(self) -> None:
        self.make_executable("docker")
        result = self.run_script(DOCKER)
        self.assertIn("[WARN] No containers found. Skipping removal.", result.stdout)
        self.assertFalse(any(call[:2] == ["docker", "rm"] for call in self.recorded_calls()))
        self.assertIn("1 skipped", result.stdout)

    def test_docker_error_failure_does_not_stop_independent_steps(self) -> None:
        self.make_executable("docker")
        self.fail_commands("docker volume prune -af")
        result = self.run_script(DOCKER, expected_returncode=1)
        self.assertIn(["docker", "network", "prune", "-f"], self.recorded_calls())
        self.assertIn(["docker", "system", "df"], self.recorded_calls())
        self.assertIn("Failed steps: Pruning unused volumes [error]", result.stdout)
        self.assertNotIn("[FINISHED] Docker cleanup process finished.", result.stdout)

    def test_docker_warning_failures_do_not_fail_script(self) -> None:
        self.make_executable("docker")
        self.fail_commands("docker builder prune -af", "docker system df")
        result = self.run_script(DOCKER)
        self.assertIn("BuildKit might be disabled or unsupported", result.stdout)
        self.assertIn("2 failed (0 errors, 2 warnings)", result.stdout)
        self.assertIn("Pruning builder cache [warn], Docker disk usage [warn]", result.stdout)
        self.assertIn("[FINISHED] Docker cleanup process finished.", result.stdout)


if __name__ == "__main__":
    unittest.main()
