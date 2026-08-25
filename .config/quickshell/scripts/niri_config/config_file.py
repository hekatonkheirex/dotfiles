import os
import shutil
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
    def __init__(self, path: str):
        self.path = Path(path)

    def read_text(self) -> str:
        return self.path.read_text()

    def apply(self, transform: Callable[[str], str]) -> WriteResult:
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
            return WriteResult(ok=True, backup_path=backup_path)
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
