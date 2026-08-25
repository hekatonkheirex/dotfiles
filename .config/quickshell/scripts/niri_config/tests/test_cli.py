import subprocess
import shutil
import sys
from pathlib import Path

import pytest

FIXTURES = Path(__file__).parent / "fixtures"


def run_cli(*args, path=None):
    cmd = [sys.executable, "-m", "scripts.niri_config", *args]
    if path is not None:
        cmd += ["--path", str(path)]
    return subprocess.run(cmd, capture_output=True, text=True, cwd=str(Path(__file__).parents[3]))


@pytest.fixture
def outputs_copy(tmp_path):
    target = tmp_path / "outputs.kdl"
    shutil.copy2(FIXTURES / "outputs.kdl", target)
    return target


def test_read_output_scale(outputs_copy):
    result = run_cli("outputs", "read", "scale", "eDP-1", path=outputs_copy)
    assert result.returncode == 0
    assert result.stdout.strip() == "1"


def test_write_output_scale(outputs_copy):
    result = run_cli("outputs", "write", "scale", "1.5", "eDP-1", path=outputs_copy)
    assert result.returncode == 0
    assert result.stdout.strip() == "OK"
    result2 = run_cli("outputs", "read", "scale", "eDP-1", path=outputs_copy)
    assert result2.stdout.strip() == "1.5"


def test_write_invalid_value_reports_error(outputs_copy):
    result = run_cli("outputs", "write", "transform", "sideways", "eDP-1", path=outputs_copy)
    assert result.returncode == 1
    assert "ERROR" in result.stderr


def test_unknown_field_errors(outputs_copy):
    result = run_cli("outputs", "read", "not-a-real-field", "eDP-1", path=outputs_copy)
    assert result.returncode == 1


def test_write_nonexistent_output_reports_clean_error(outputs_copy):
    result = run_cli("outputs", "write", "scale", "1.5", "nonexistent-output", path=outputs_copy)
    assert result.returncode == 1
    assert "ERROR" in result.stderr
    assert "Traceback" not in result.stderr


def test_decorations_gaps_roundtrip(tmp_path):
    target = tmp_path / "decorations.kdl"
    shutil.copy2(FIXTURES / "decorations.kdl", target)
    result = run_cli("decorations", "write", "gaps", "20", path=target)
    assert result.returncode == 0
    result2 = run_cli("decorations", "read", "gaps", path=target)
    assert result2.stdout.strip() == "20"


def test_hot_corner_write_and_read(tmp_path):
    target = tmp_path / "inputs.kdl"
    shutil.copy2(FIXTURES / "inputs.kdl", target)
    result = run_cli("inputs", "write", "hot-corner", "true", "top-left", path=target)
    assert result.returncode == 0, result.stderr
    result2 = run_cli("inputs", "read", "hot-corner", "top-left", path=target)
    assert result2.stdout.strip() == "true"


def test_animation_duration_write_and_read(tmp_path):
    target = tmp_path / "decorations.kdl"
    shutil.copy2(FIXTURES / "decorations.kdl", target)
    result = run_cli("decorations", "write", "animation-duration-ms", "300", "window-open", path=target)
    assert result.returncode == 0, result.stderr
    result2 = run_cli("decorations", "read", "animation-duration-ms", "window-open", path=target)
    assert result2.stdout.strip() == "300"


def test_write_invalid_value_parse_error(outputs_copy):
    result = run_cli("outputs", "write", "scale", "not-a-number", "eDP-1", path=outputs_copy)
    assert result.returncode == 1
    assert "ERROR" in result.stderr
