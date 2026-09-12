import os
import stat
import subprocess
from pathlib import Path


SCRIPT_PATH = Path(__file__).parents[1] / "safe-logout.sh"


def _write_command(path: Path, body: str) -> None:
    path.write_text(f"#!/usr/bin/env bash\nset -euo pipefail\n{body}")
    path.chmod(path.stat().st_mode | stat.S_IXUSR)


def _run_logout(
    tmp_path: Path, niri_status: int, busctl_status: int
) -> list[str]:
    bin_dir = tmp_path / "bin"
    bin_dir.mkdir()
    trace_file = tmp_path / "trace"
    state_file = tmp_path / "terminated"

    _write_command(
        bin_dir / "niri",
        'printf "niri %s\\n" "$*" >> "$TRACE_FILE"\n'
        'exit "$NIRI_STATUS"\n',
    )
    _write_command(
        bin_dir / "busctl",
        'printf "busctl %s\\n" "$*" >> "$TRACE_FILE"\n'
        'exit "$BUSCTL_STATUS"\n',
    )
    _write_command(
        bin_dir / "loginctl",
        'printf "loginctl %s\\n" "$*" >> "$TRACE_FILE"\n'
        'if [[ "$1" == "show-session" ]]; then\n'
        '  [[ ! -e "$STATE_FILE" ]]\n'
        'elif [[ "$1" == "terminate-session" || "$1" == "kill-session" ]]; then\n'
        '  touch "$STATE_FILE"\n'
        'fi\n',
    )
    _write_command(bin_dir / "sleep", "exit 0\n")

    environment = os.environ.copy()
    environment.update(
        {
            "PATH": f"{bin_dir}:{environment['PATH']}",
            "TRACE_FILE": str(trace_file),
            "STATE_FILE": str(state_file),
            "NIRI_STATUS": str(niri_status),
            "BUSCTL_STATUS": str(busctl_status),
            "XDG_CURRENT_DESKTOP": "Niri",
            "XDG_SESSION_ID": "42",
        }
    )

    result = subprocess.run(
        [str(SCRIPT_PATH)],
        capture_output=True,
        text=True,
        env=environment,
        check=False,
    )
    assert result.returncode == 0, result.stderr
    return trace_file.read_text().splitlines()


def test_successful_niri_quit_prepares_sddm_without_logind_teardown(tmp_path):
    trace = _run_logout(tmp_path, niri_status=0, busctl_status=0)

    assert trace == [
        "busctl --system call org.freedesktop.DisplayManager "
        "/org/freedesktop/DisplayManager/Seat0 "
        "org.freedesktop.DisplayManager.Seat SwitchToGreeter",
        "niri msg action quit --skip-confirmation",
    ]


def test_failed_sddm_handoff_still_quits_niri_cleanly(tmp_path):
    trace = _run_logout(tmp_path, niri_status=0, busctl_status=1)

    assert trace == [
        "busctl --system call org.freedesktop.DisplayManager "
        "/org/freedesktop/DisplayManager/Seat0 "
        "org.freedesktop.DisplayManager.Seat SwitchToGreeter",
        "niri msg action quit --skip-confirmation",
    ]


def test_failed_niri_quit_falls_back_to_logind(tmp_path):
    trace = _run_logout(tmp_path, niri_status=1, busctl_status=1)

    assert trace[:3] == [
        "busctl --system call org.freedesktop.DisplayManager "
        "/org/freedesktop/DisplayManager/Seat0 "
        "org.freedesktop.DisplayManager.Seat SwitchToGreeter",
        "niri msg action quit --skip-confirmation",
        "loginctl show-session 42",
    ]
    assert "loginctl terminate-session 42" in trace
