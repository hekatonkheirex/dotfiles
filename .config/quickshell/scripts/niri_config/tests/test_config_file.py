import os
import shutil
import time
from pathlib import Path

import pytest

from scripts.niri_config.config_file import NiriConfigFile

FIXTURE = Path(__file__).parent / "fixtures" / "outputs.kdl"


@pytest.fixture
def working_copy(tmp_path):
    target = tmp_path / "outputs.kdl"
    shutil.copy2(FIXTURE, target)
    return target


def test_apply_writes_valid_change(working_copy):
    cfg = NiriConfigFile(str(working_copy))
    result = cfg.apply(lambda text: text.replace("scale 1", "scale 2"))
    assert result.ok
    assert "scale 2" in working_copy.read_text()


def test_apply_noop_when_transform_returns_same_text(working_copy):
    cfg = NiriConfigFile(str(working_copy))
    original_mtime = working_copy.stat().st_mtime
    result = cfg.apply(lambda text: text)
    assert result.ok
    assert result.backup_path is None
    assert working_copy.stat().st_mtime == original_mtime


def test_apply_aborts_on_invalid_kdl(working_copy):
    cfg = NiriConfigFile(str(working_copy))
    original_text = working_copy.read_text()
    result = cfg.apply(lambda text: text + '\noutput "broken" {\n  scale bogus\n')
    assert not result.ok
    assert result.error
    assert working_copy.read_text() == original_text  # untouched


def test_apply_creates_backup_on_success(working_copy):
    cfg = NiriConfigFile(str(working_copy))
    original_text = working_copy.read_text()
    result = cfg.apply(lambda text: text.replace("scale 1", "scale 3"))
    assert result.ok
    assert result.backup_path is not None
    assert Path(result.backup_path).read_text() == original_text


def test_backup_pruned_to_last_ten(working_copy):
    cfg = NiriConfigFile(str(working_copy))
    for i in range(12):
        cfg.apply(lambda text, i=i: text.replace("scale 1", f"scale {i}") if i == 0
                  else text.replace(f"scale {i - 1}", f"scale {i}"))
        time.sleep(0.01)  # ensure distinct timestamps
    backups = sorted((working_copy.parent / ".backups").glob("outputs.kdl.*.kdl"))
    assert len(backups) == 10


def test_apply_preserves_file_mode(working_copy):
    os.chmod(working_copy, 0o644)
    cfg = NiriConfigFile(str(working_copy))
    result = cfg.apply(lambda text: text.replace("scale 1", "scale 2"))
    assert result.ok
    assert working_copy.stat().st_mode & 0o777 == 0o644
