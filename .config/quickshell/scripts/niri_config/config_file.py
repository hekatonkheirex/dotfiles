import fcntl
import os
import shutil
import stat
import subprocess
import tempfile
import time
from dataclasses import dataclass
from pathlib import Path
from typing import Callable, Optional

BACKUP_DIR_NAME = ".backups"
MAX_BACKUPS_PER_FILE = 10


@dataclass
class WriteResult:
    ok: bool
    error: Optional[str] = None
    backup_path: Optional[str] = None


class NiriConfigFile:
    def __init__(self, path: str, reload_live: bool = False):
        self.path = Path(path)
        self.reload_live = reload_live

    def read_text(self) -> str:
        return self.path.read_text()

    def apply(self, transform: Callable[[str], str]) -> WriteResult:
        with self._lock():
            original = self.read_text()
            new_text = transform(original)
            if new_text == original:
                return WriteResult(ok=True)

            fd, tmp_path = tempfile.mkstemp(suffix=".kdl", dir=str(self.path.parent))
            try:
                with os.fdopen(fd, "w") as f:
                    f.write(new_text)

                proc = subprocess.run(
                    ["niri", "validate", "-c", tmp_path],
                    capture_output=True, text=True,
                )
                if proc.returncode != 0:
                    return WriteResult(ok=False, error=proc.stderr.strip())

                os.chmod(tmp_path, self.path.stat().st_mode)
                backup_path = self._backup()
                os.replace(tmp_path, str(self.path))

                if self.reload_live:
                    reload_error = self._reload_live_config()
                    if reload_error:
                        self._restore(original)
                        return WriteResult(
                            ok=False,
                            error=(
                                "Live Niri reload failed; the file was restored: "
                                + reload_error
                            ),
                        )

                return WriteResult(ok=True, backup_path=backup_path)
            finally:
                if os.path.exists(tmp_path):
                    os.unlink(tmp_path)

    def _lock(self):
        xdg_runtime_dir = os.environ.get("XDG_RUNTIME_DIR")
        candidates = []
        if xdg_runtime_dir:
            candidates.append(Path(xdg_runtime_dir) / "quickshell")
        candidates.append(Path.home() / ".cache" / "quickshell")
        candidates.append(Path(tempfile.gettempdir()) / f"quickshell-{os.getuid()}")

        last_error = None
        for runtime_dir in candidates:
            lock_file = None
            try:
                runtime_dir.mkdir(mode=0o700, parents=True, exist_ok=True)
                if stat.S_IMODE(runtime_dir.stat().st_mode) != 0o700:
                    os.chmod(runtime_dir, 0o700)
                lock_path = runtime_dir / "niri-config.lock"
                lock_file = open(lock_path, "a+")
                os.chmod(lock_path, 0o600)
                fcntl.flock(lock_file.fileno(), fcntl.LOCK_EX)
                return _LockedFile(lock_file)
            except OSError as exc:
                last_error = exc
                if lock_file is not None:
                    lock_file.close()

        raise last_error or OSError("Could not create Niri config lock")

    def _reload_live_config(self) -> Optional[str]:
        try:
            proc = subprocess.run(
                ["niri", "msg", "action", "load-config-file"],
                capture_output=True,
                text=True,
            )
        except OSError as exc:
            return str(exc)
        if proc.returncode == 0:
            return None
        return (proc.stderr or proc.stdout).strip() or f"exit code {proc.returncode}"

    def _restore(self, original: str) -> None:
        fd, tmp_path = tempfile.mkstemp(suffix=".kdl", dir=str(self.path.parent))
        try:
            with os.fdopen(fd, "w") as f:
                f.write(original)
            os.chmod(tmp_path, self.path.stat().st_mode)
            os.replace(tmp_path, str(self.path))
        finally:
            if os.path.exists(tmp_path):
                os.unlink(tmp_path)

    def _backup(self) -> str:
        backup_dir = self.path.parent / BACKUP_DIR_NAME
        backup_dir.mkdir(exist_ok=True)
        timestamp = int(time.time() * 1000)
        backup_path = backup_dir / f"{self.path.name}.{timestamp}.kdl"
        shutil.copy2(self.path, backup_path)
        self._prune_backups(backup_dir)
        return str(backup_path)

    def _prune_backups(self, backup_dir: Path) -> None:
        pattern = f"{self.path.name}.*.kdl"
        backups = sorted(backup_dir.glob(pattern), key=lambda p: p.stat().st_mtime)
        while len(backups) > MAX_BACKUPS_PER_FILE:
            backups.pop(0).unlink()


class _LockedFile:
    def __init__(self, file):
        self.file = file

    def __enter__(self):
        return self.file

    def __exit__(self, exc_type, exc, traceback):
        fcntl.flock(self.file.fileno(), fcntl.LOCK_UN)
        self.file.close()
