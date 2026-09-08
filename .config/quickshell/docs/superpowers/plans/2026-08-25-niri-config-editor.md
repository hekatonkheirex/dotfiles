# Niri Config Editor (Display & Input + Decorations) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a real read/write editor for niri's Outputs, Input, and Decorations config (currently only viewable by hand-editing `.kdl` files) into this shell's Settings panel, safely — every write is validated with `niri validate` and backed up before it touches the real file.

**Architecture:** A Python package (`scripts/niri_config/`) does targeted regex-based reads/writes of specific fields inside niri's `.kdl` config files — never a general parse/reserialize, so untouched lines (including the user's own comments) survive byte-for-byte. QML shells out to it via a CLI entry point, using the same `Process`-based pattern already used for `statsProc`/`uptimeProc` in `SettingsPanel.qml`. Two new reusable QML primitives (`RemoteSwitchRow`, `RemoteSliderRow`, `RemoteTextRow`) wrap that `Process` plumbing once so each settings tab is just a data table plus a `Repeater`, matching how `tabRepeater.model` and `searchEntries` already work in this codebase.

**Tech Stack:** Python 3 (stdlib only — `re`, `subprocess`, `tempfile`, `shutil`, `pathlib`, `dataclasses`), `pytest` for tests, QML/Quickshell for UI, niri's own `niri validate` CLI as the safety gate.

## Global Constraints

- No new Python dependency — stdlib only. (Spec: rejected `python-kdl-py` in favor of targeted regex edits, to avoid reformatting files and dropping existing comments.)
- Every write goes through: apply in-memory → write to temp file → `niri validate -c <temp>` → on success, back up the original then atomically replace it; on failure, abort and leave the real file untouched. (Spec: Architecture.)
- Backups live at `~/.config/niri/.backups/<file>.<timestamp>.kdl`, capped at the last 10 per file. (Spec: Architecture.)
- Window rules (`windowrules.kdl`) are out of scope for this plan — separate future spec. (Spec: Non-goals.)
- Test fixtures are **copies** of this machine's real `.kdl` files, checked into the repo under `scripts/niri_config/tests/fixtures/` — tests never touch `~/.config/niri/` directly. (Spec: Testing.)
- Gate tests only, no eval suite — this is deterministic text transformation, not LLM-judged output. (Spec: Testing.)

---

## File Structure

```
scripts/niri_config/
  __init__.py          # empty, marks the package
  __main__.py           # CLI: read/write dispatch, calls into outputs.py/inputs.py/decorations.py
  kdl_edit.py            # generic block-finding + scalar read/write primitives (no niri-specific knowledge)
  config_file.py          # NiriConfigFile: validate + backup + atomic write pipeline
  outputs.py               # per-output fields: mode, scale, transform, position
  inputs.py                 # touchpad/mouse/trackpoint/gestures fields
  decorations.py             # layout/animations/blur/cursor fields
  tests/
    fixtures/
      outputs.kdl
      inputs.kdl
      decorations.kdl
    test_kdl_edit.py
    test_config_file.py
    test_outputs.py
    test_inputs.py
    test_decorations.py
    test_cli.py

bar/primitives/
  RemoteSwitchRow.qml    # ListItem + SwitchControl wired to a niri_config CLI field
  RemoteSliderRow.qml     # label row + SliderControl wired to a niri_config CLI field
  RemoteTextRow.qml        # label row + a small enum/text control wired to a niri_config CLI field

bar/settings/
  DisplayInputTab.qml    # new tab: Outputs section + Input section
  AppearanceTab.qml       # modified: new "Window Manager" section appended (decorations fields)

bar/SettingsPanel.qml    # modified: new sidebar tab entry, tabContainer child, currentTab bound, searchEntries
```

---

### Task 1: `kdl_edit.py` — generic KDL scalar read/write primitives

**Files:**
- Create: `scripts/niri_config/__init__.py` (empty)
- Create: `scripts/niri_config/kdl_edit.py`
- Test: `scripts/niri_config/tests/test_kdl_edit.py`

**Interfaces:**
- Produces: `find_block(text, header_pattern) -> (int, int)`, `find_nested_block(text, outer_span, inner_pattern) -> (int, int)`, `read_number(text, span, key) -> float | None`, `write_number(text, span, key, value) -> str`, `read_string(text, span, key) -> str | None`, `write_string(text, span, key, value) -> str`, `read_bool_kv(text, span, key) -> bool | None`, `write_bool_kv(text, span, key, value) -> str`, `read_flag(text, span, name) -> bool`, `write_flag(text, span, name, enabled) -> str`, `read_on_off(text, span) -> bool | None`, `write_on_off(text, span, enabled) -> str`, `read_named_args(text, span, key, arg_names) -> tuple[float, ...] | None`, `write_named_args(text, span, key, arg_names, values) -> str`. All `span` values are `(start, end)` character offsets into `text` for the region strictly inside a block's `{` `}`. These are consumed by every later task.

- [ ] **Step 1: Write the failing tests**

```python
# scripts/niri_config/tests/test_kdl_edit.py
from scripts.niri_config import kdl_edit as k

SAMPLE = '''\
touchpad {
    tap
    natural-scroll
    scroll-method "two-finger"
}

mouse {
}

output "eDP-1" {
  mode "1920x1080@60.020"
  scale 1
  position x=1280 y=0
}
'''


def _span(header):
    return k.find_block(SAMPLE, header)


def test_find_block_locates_body():
    start, end = _span(r'touchpad\s*\{')
    assert SAMPLE[start:end].strip().startswith("tap")


def test_find_block_missing_raises():
    import pytest
    with pytest.raises(ValueError):
        k.find_block(SAMPLE, r'nonexistent\s*\{')


def test_find_nested_block():
    outer = k.find_block(SAMPLE, r'output\s+"eDP-1"\s*\{')
    # position is a scalar line, not a block, so nest into touchpad->none;
    # instead prove nesting against a synthetic multi-level sample.
    nested_sample = "outer {\n  inner {\n    x 1\n  }\n}\n"
    outer2 = k.find_block(nested_sample, r'outer\s*\{')
    inner = k.find_nested_block(nested_sample, outer2, r'inner\s*\{')
    assert nested_sample[inner[0]:inner[1]].strip() == "x 1"


def test_read_write_number_replace():
    span = _span(r'output\s+"eDP-1"\s*\{')
    assert k.read_number(SAMPLE, span, "scale") == 1.0
    new_text = k.write_number(SAMPLE, span, "scale", 1.5)
    span2 = k.find_block(new_text, r'output\s+"eDP-1"\s*\{')
    assert k.read_number(new_text, span2, "scale") == 1.5
    # untouched fields survive
    assert k.read_string(new_text, span2, "mode") == "1920x1080@60.020"


def test_write_number_inserts_when_absent():
    span = _span(r'mouse\s*\{')
    assert k.read_number(SAMPLE, span, "accel-speed") is None
    new_text = k.write_number(SAMPLE, span, "accel-speed", 0.2)
    span2 = k.find_block(new_text, r'mouse\s*\{')
    assert k.read_number(new_text, span2, "accel-speed") == 0.2


def test_read_write_string_replace():
    span = _span(r'output\s+"eDP-1"\s*\{')
    assert k.read_string(SAMPLE, span, "mode") == "1920x1080@60.020"
    new_text = k.write_string(SAMPLE, span, "mode", "2560x1440@60.000")
    span2 = k.find_block(new_text, r'output\s+"eDP-1"\s*\{')
    assert k.read_string(new_text, span2, "mode") == "2560x1440@60.000"


def test_flag_read_write_roundtrip():
    span = _span(r'touchpad\s*\{')
    assert k.read_flag(SAMPLE, span, "tap") is True
    assert k.read_flag(SAMPLE, span, "disabled-on-external-mouse") is False
    disabled = k.write_flag(SAMPLE, span, "tap", False)
    span2 = k.find_block(disabled, r'touchpad\s*\{')
    assert k.read_flag(disabled, span2, "tap") is False
    enabled = k.write_flag(disabled, span2, "tap", True)
    span3 = k.find_block(enabled, r'touchpad\s*\{')
    assert k.read_flag(enabled, span3, "tap") is True


def test_flag_write_noop_when_already_matches():
    span = _span(r'touchpad\s*\{')
    same = k.write_flag(SAMPLE, span, "tap", True)
    assert same == SAMPLE


def test_bool_kv_roundtrip():
    text = "layout {\n  always-center-single-column true\n}\n"
    span = k.find_block(text, r'layout\s*\{')
    assert k.read_bool_kv(text, span, "always-center-single-column") is True
    new_text = k.write_bool_kv(text, span, "always-center-single-column", False)
    span2 = k.find_block(new_text, r'layout\s*\{')
    assert k.read_bool_kv(new_text, span2, "always-center-single-column") is False


def test_on_off_roundtrip():
    text = "focus-ring {\n  on\n  width 2\n}\n"
    span = k.find_block(text, r'focus-ring\s*\{')
    assert k.read_on_off(text, span) is True
    new_text = k.write_on_off(text, span, False)
    span2 = k.find_block(new_text, r'focus-ring\s*\{')
    assert k.read_on_off(new_text, span2) is False
    # width survives untouched
    assert k.read_number(new_text, span2, "width") == 2.0


def test_on_off_inserts_when_absent():
    text = "blur {\n  passes 3\n}\n"
    span = k.find_block(text, r'blur\s*\{')
    assert k.read_on_off(text, span) is None
    new_text = k.write_on_off(text, span, False)
    span2 = k.find_block(new_text, r'blur\s*\{')
    assert k.read_on_off(new_text, span2) is False
    assert k.read_number(new_text, span2, "passes") == 3.0


def test_named_args_roundtrip():
    span = _span(r'output\s+"eDP-1"\s*\{')
    assert k.read_named_args(SAMPLE, span, "position", ["x", "y"]) == (1280.0, 0.0)
    new_text = k.write_named_args(SAMPLE, span, "position", ["x", "y"], [0.0, 0.0])
    span2 = k.find_block(new_text, r'output\s+"eDP-1"\s*\{')
    assert k.read_named_args(new_text, span2, "position", ["x", "y"]) == (0.0, 0.0)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest scripts/niri_config/tests/test_kdl_edit.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.niri_config'` (nothing exists yet)

- [ ] **Step 3: Create the package and implement `kdl_edit.py`**

```python
# scripts/niri_config/__init__.py
```

```python
# scripts/niri_config/kdl_edit.py
"""Deterministic KDL fragment editing.

Not a general KDL parser. Each function only understands the exact scalar
shapes niri's own config files use (bare flag, `key value`, `key "string"`,
`key true/false`, bare `on`/`off`, `key a=1 b=2`). It locates a field by
regex within a caller-supplied block span and edits only that one line,
so every other byte in the file — including comments — is untouched.
"""
import re


def find_block(text: str, header_pattern: str) -> tuple[int, int]:
    """Return (body_start, body_end): offsets into `text` spanning the
    region strictly between the `{` and matching `}` of the first block
    whose opening line matches `header_pattern`."""
    m = re.search(header_pattern, text)
    if m is None:
        raise ValueError(f"block not found: {header_pattern!r}")
    brace_start = text.index("{", m.start())
    depth = 0
    i = brace_start
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return (brace_start + 1, i)
        i += 1
    raise ValueError(f"unclosed block: {header_pattern!r}")


def find_nested_block(text: str, outer_span: tuple[int, int], inner_pattern: str) -> tuple[int, int]:
    """Like find_block, but searches only within outer_span and returns
    offsets translated back into the original `text`."""
    outer_start, outer_end = outer_span
    inner_start, inner_end = find_block(text[outer_start:outer_end], inner_pattern)
    return (outer_start + inner_start, outer_start + inner_end)


def _format_number(value: float) -> str:
    value = float(value)
    return str(int(value)) if value.is_integer() else repr(value)


def _insert_point(block: str) -> int:
    """First line inside a block, right after its opening newline."""
    return block.index("\n") + 1 if "\n" in block else 0


def read_number(text: str, span: tuple[int, int], key: str) -> float | None:
    block = text[span[0]:span[1]]
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]+(-?[0-9]+(?:\.[0-9]+)?)', block)
    return float(m.group(1)) if m else None


def write_number(text: str, span: tuple[int, int], key: str, value: float) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + r'[ \t]+-?[0-9]+(?:\.[0-9]+)?')
    m = pattern.search(block)
    formatted = _format_number(value)
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + formatted + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + formatted + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_string(text: str, span: tuple[int, int], key: str) -> str | None:
    block = text[span[0]:span[1]]
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]+"([^"]*)"', block)
    return m.group(1) if m else None


def write_string(text: str, span: tuple[int, int], key: str, value: str) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + r'[ \t]+"[^"]*"')
    m = pattern.search(block)
    literal = '"' + value + '"'
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + literal + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + literal + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_bool_kv(text: str, span: tuple[int, int], key: str) -> bool | None:
    block = text[span[0]:span[1]]
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]+(true|false)\b', block)
    return (m.group(1) == "true") if m else None


def write_bool_kv(text: str, span: tuple[int, int], key: str, value: bool) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + r'[ \t]+(?:true|false)\b')
    m = pattern.search(block)
    literal = "true" if value else "false"
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + literal + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + literal + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_flag(text: str, span: tuple[int, int], name: str) -> bool:
    block = text[span[0]:span[1]]
    return re.search(r'(?m)^[ \t]*' + re.escape(name) + r'[ \t]*(?://.*)?$', block) is not None


def write_flag(text: str, span: tuple[int, int], name: str, enabled: bool) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^[ \t]*' + re.escape(name) + r'[ \t]*(?://.*)?\n?')
    m = pattern.search(block)
    if enabled:
        if m:
            return text
        at = _insert_point(block)
        new_block = block[:at] + "  " + name + "\n" + block[at:]
    else:
        if not m:
            return text
        new_block = block[:m.start()] + block[m.end():]
    return text[:span[0]] + new_block + text[span[1]:]


def read_on_off(text: str, span: tuple[int, int]) -> bool | None:
    block = text[span[0]:span[1]]
    if re.search(r'(?m)^[ \t]*on[ \t]*(?://.*)?$', block):
        return True
    if re.search(r'(?m)^[ \t]*off[ \t]*(?://.*)?$', block):
        return False
    return None


def write_on_off(text: str, span: tuple[int, int], enabled: bool) -> str:
    block = text[span[0]:span[1]]
    word = "on" if enabled else "off"
    pattern = re.compile(r'(?m)^([ \t]*)(on|off)[ \t]*(?://.*)?$')
    m = pattern.search(block)
    if m:
        new_block = block[:m.start()] + m.group(1) + word + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + word + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_named_args(text: str, span: tuple[int, int], key: str, arg_names: list[str]) -> tuple[float, ...] | None:
    block = text[span[0]:span[1]]
    args_pattern = "".join(r'\s+' + re.escape(a) + r'=(-?[0-9]+(?:\.[0-9]+)?)' for a in arg_names)
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + args_pattern, block)
    return tuple(float(g) for g in m.groups()) if m else None


def write_named_args(text: str, span: tuple[int, int], key: str, arg_names: list[str], values: list[float]) -> str:
    block = text[span[0]:span[1]]
    args_pattern = "".join(r'\s+' + re.escape(a) + r'=-?[0-9]+(?:\.[0-9]+)?' for a in arg_names)
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + args_pattern)
    m = pattern.search(block)
    formatted = " ".join(f"{a}={_format_number(v)}" for a, v in zip(arg_names, values))
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + formatted + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + formatted + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest scripts/niri_config/tests/test_kdl_edit.py -v`
Expected: PASS (13 tests)

- [ ] **Step 5: Commit**

```bash
git add scripts/niri_config/__init__.py scripts/niri_config/kdl_edit.py scripts/niri_config/tests/test_kdl_edit.py
git commit -m "feat(niri_config): add generic KDL scalar read/write primitives"
```

(If this directory turns out not to be a plain git repo when you run this — check with `git rev-parse --is-inside-work-tree` first — skip the commit steps in every task below and note it in your final report instead; this repo is yadm-managed per existing project convention.)

---

### Task 2: `config_file.py` — validate + backup + atomic write pipeline

**Files:**
- Create: `scripts/niri_config/config_file.py`
- Test: `scripts/niri_config/tests/test_config_file.py`

**Interfaces:**
- Consumes: nothing from Task 1 directly (this module is KDL-content-agnostic; it wraps whole-file text transforms).
- Produces: `NiriConfigFile(path)` with `.read_text() -> str`, `.apply(transform: Callable[[str], str]) -> WriteResult`, and `WriteResult(ok: bool, error: str | None, backup_path: str | None)`. Task 6 (CLI) is the only later task that calls this directly.

- [ ] **Step 1: Confirm niri validate's scope (manual, one-time check)**

Before writing tests that assume this, confirm on the running system:

```bash
cp ~/.config/niri/outputs.kdl /tmp/niri-validate-check.kdl
niri validate -c /tmp/niri-validate-check.kdl   # expect: "config is valid", exit 0
printf 'output "x" {\n  scale bogus\n' > /tmp/niri-validate-check-broken.kdl
niri validate -c /tmp/niri-validate-check-broken.kdl  # expect: parse error, exit 1
rm /tmp/niri-validate-check.kdl /tmp/niri-validate-check-broken.kdl
```

This was already confirmed once during design (see the spec's "Resolved during design" section) — this step just re-confirms on the machine actually running the implementation, since it's cheap and this whole task's safety guarantee depends on it. If `niri validate` behaves differently than expected (e.g. requires the full `config.kdl` tree), stop and re-read the spec's Architecture section before proceeding — the temp-file validation approach below assumes standalone fragment validation works.

- [ ] **Step 2: Write the failing tests**

```python
# scripts/niri_config/tests/test_config_file.py
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
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `python3 -m pytest scripts/niri_config/tests/test_config_file.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.niri_config.config_file'`

- [ ] **Step 4: Implement `config_file.py`**

```python
# scripts/niri_config/config_file.py
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
```

- [ ] **Step 5: Copy the real files as test fixtures**

```bash
mkdir -p scripts/niri_config/tests/fixtures
cp ~/.config/niri/outputs.kdl scripts/niri_config/tests/fixtures/outputs.kdl
cp ~/.config/niri/inputs.kdl scripts/niri_config/tests/fixtures/inputs.kdl
cp ~/.config/niri/decorations.kdl scripts/niri_config/tests/fixtures/decorations.kdl
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `python3 -m pytest scripts/niri_config/tests/test_config_file.py -v`
Expected: PASS (5 tests). Note: this test suite shells out to the real `niri validate` binary (no mocking) — it must be run on a machine with niri installed, which matches every other suite in this repo (`run-gates`/`run-evals` already assume this is niri's own config directory).

- [ ] **Step 7: Commit**

```bash
git add scripts/niri_config/config_file.py scripts/niri_config/tests/test_config_file.py scripts/niri_config/tests/fixtures/
git commit -m "feat(niri_config): add validate+backup+atomic-write pipeline"
```

---

### Task 3: `outputs.py` — per-output fields

**Files:**
- Create: `scripts/niri_config/outputs.py`
- Test: `scripts/niri_config/tests/test_outputs.py`

**Interfaces:**
- Consumes: `kdl_edit.find_block/read_number/write_number/read_string/write_string/read_named_args/write_named_args` (Task 1).
- Produces: `read_scale(text, name) -> float | None`, `write_scale(text, name, value) -> str`, `read_transform(text, name) -> str | None`, `write_transform(text, name, value) -> str`, `read_mode(text, name) -> str | None`, `write_mode(text, name, value) -> str`, `read_position(text, name) -> tuple[float, float] | None`, `write_position(text, name, x, y) -> str`. Consumed by Task 6 (CLI).

- [ ] **Step 1: Write the failing tests**

```python
# scripts/niri_config/tests/test_outputs.py
from pathlib import Path
from scripts.niri_config import outputs as o

FIXTURE_TEXT = (Path(__file__).parent / "fixtures" / "outputs.kdl").read_text()


def test_read_scale():
    assert o.read_scale(FIXTURE_TEXT, "eDP-1") == 1.0


def test_write_scale_roundtrip():
    new_text = o.write_scale(FIXTURE_TEXT, "eDP-1", 1.25)
    assert o.read_scale(new_text, "eDP-1") == 1.25
    # other output untouched
    assert o.read_scale(new_text, "HDMI-A-2") == 1.0


def test_read_write_transform():
    assert o.read_transform(FIXTURE_TEXT, "eDP-1") == "normal"
    new_text = o.write_transform(FIXTURE_TEXT, "eDP-1", "90")
    assert o.read_transform(new_text, "eDP-1") == "90"


def test_read_write_mode():
    assert o.read_mode(FIXTURE_TEXT, "eDP-1") == "1920x1080@60.020"
    new_text = o.write_mode(FIXTURE_TEXT, "eDP-1", "1920x1080@48.016")
    assert o.read_mode(new_text, "eDP-1") == "1920x1080@48.016"


def test_read_write_position():
    assert o.read_position(FIXTURE_TEXT, "eDP-1") == (1280.0, 0.0)
    new_text = o.write_position(FIXTURE_TEXT, "eDP-1", 0.0, 0.0)
    assert o.read_position(new_text, "eDP-1") == (0.0, 0.0)


def test_position_absent_then_insertable():
    assert o.read_position(FIXTURE_TEXT, "HDMI-A-2") is None
    new_text = o.write_position(FIXTURE_TEXT, "HDMI-A-2", 1920.0, 0.0)
    assert o.read_position(new_text, "HDMI-A-2") == (1920.0, 0.0)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest scripts/niri_config/tests/test_outputs.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.niri_config.outputs'`

- [ ] **Step 3: Implement `outputs.py`**

```python
# scripts/niri_config/outputs.py
"""Read/write fields on a single named `output "<name>" { ... }` block."""
import re
from . import kdl_edit as k


def _span(text: str, name: str) -> tuple[int, int]:
    return k.find_block(text, r'output\s+"' + re.escape(name) + r'"\s*\{')


def read_scale(text: str, name: str) -> float | None:
    return k.read_number(text, _span(text, name), "scale")


def write_scale(text: str, name: str, value: float) -> str:
    return k.write_number(text, _span(text, name), "scale", value)


def read_transform(text: str, name: str) -> str | None:
    return k.read_string(text, _span(text, name), "transform")


def write_transform(text: str, name: str, value: str) -> str:
    return k.write_string(text, _span(text, name), "transform", value)


def read_mode(text: str, name: str) -> str | None:
    return k.read_string(text, _span(text, name), "mode")


def write_mode(text: str, name: str, value: str) -> str:
    return k.write_string(text, _span(text, name), "mode", value)


def read_position(text: str, name: str) -> tuple[float, float] | None:
    return k.read_named_args(text, _span(text, name), "position", ["x", "y"])


def write_position(text: str, name: str, x: float, y: float) -> str:
    return k.write_named_args(text, _span(text, name), "position", ["x", "y"], [x, y])
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest scripts/niri_config/tests/test_outputs.py -v`
Expected: PASS (6 tests)

- [ ] **Step 5: Commit**

```bash
git add scripts/niri_config/outputs.py scripts/niri_config/tests/test_outputs.py
git commit -m "feat(niri_config): add outputs.kdl field read/write"
```

---

### Task 4: `inputs.py` — touchpad/mouse/trackpoint/gestures fields

**Files:**
- Create: `scripts/niri_config/inputs.py`
- Test: `scripts/niri_config/tests/test_inputs.py`

**Interfaces:**
- Consumes: `kdl_edit` primitives (Task 1).
- Produces (all take/return whole-file `text`): `read_touchpad_tap/write_touchpad_tap`, `read_touchpad_natural_scroll/write_touchpad_natural_scroll`, `read_touchpad_scroll_method/write_touchpad_scroll_method`, `read_mouse_natural_scroll/write_mouse_natural_scroll`, `read_mouse_accel_speed/write_mouse_accel_speed`, `read_mouse_accel_profile/write_mouse_accel_profile`, `read_trackpoint_natural_scroll/write_trackpoint_natural_scroll`, `read_trackpoint_accel_speed/write_trackpoint_accel_speed`, `read_view_scroll_trigger_width/write_view_scroll_trigger_width`, `read_view_scroll_delay_ms/write_view_scroll_delay_ms`, `read_view_scroll_max_speed/write_view_scroll_max_speed`, `read_workspace_switch_trigger_height/write_workspace_switch_trigger_height`, `read_workspace_switch_delay_ms/write_workspace_switch_delay_ms`, `read_workspace_switch_max_speed/write_workspace_switch_max_speed`, `read_hot_corner/write_hot_corner(text, corner: str, enabled)` where `corner` is one of `bottom-right`/`bottom-left`/`top-right`/`top-left`. Consumed by Task 6 (CLI).

- [ ] **Step 1: Write the failing tests**

```python
# scripts/niri_config/tests/test_inputs.py
from pathlib import Path
from scripts.niri_config import inputs as i

FIXTURE_TEXT = (Path(__file__).parent / "fixtures" / "inputs.kdl").read_text()


def test_touchpad_tap_roundtrip():
    assert i.read_touchpad_tap(FIXTURE_TEXT) is True
    off = i.write_touchpad_tap(FIXTURE_TEXT, False)
    assert i.read_touchpad_tap(off) is False
    on = i.write_touchpad_tap(off, True)
    assert i.read_touchpad_tap(on) is True


def test_touchpad_natural_scroll_roundtrip():
    assert i.read_touchpad_natural_scroll(FIXTURE_TEXT) is True
    new_text = i.write_touchpad_natural_scroll(FIXTURE_TEXT, False)
    assert i.read_touchpad_natural_scroll(new_text) is False


def test_touchpad_scroll_method():
    assert i.read_touchpad_scroll_method(FIXTURE_TEXT) == "two-finger"
    new_text = i.write_touchpad_scroll_method(FIXTURE_TEXT, "edge")
    assert i.read_touchpad_scroll_method(new_text) == "edge"


def test_mouse_fields_absent_then_insertable():
    assert i.read_mouse_natural_scroll(FIXTURE_TEXT) is False
    assert i.read_mouse_accel_speed(FIXTURE_TEXT) is None
    assert i.read_mouse_accel_profile(FIXTURE_TEXT) is None
    new_text = i.write_mouse_natural_scroll(FIXTURE_TEXT, True)
    new_text = i.write_mouse_accel_speed(new_text, 0.3)
    new_text = i.write_mouse_accel_profile(new_text, "flat")
    assert i.read_mouse_natural_scroll(new_text) is True
    assert i.read_mouse_accel_speed(new_text) == 0.3
    assert i.read_mouse_accel_profile(new_text) == "flat"


def test_trackpoint_fields():
    assert i.read_trackpoint_natural_scroll(FIXTURE_TEXT) is True
    assert i.read_trackpoint_accel_speed(FIXTURE_TEXT) == 0.2
    new_text = i.write_trackpoint_accel_speed(FIXTURE_TEXT, 0.5)
    assert i.read_trackpoint_accel_speed(new_text) == 0.5


def test_dnd_edge_view_scroll_fields():
    assert i.read_view_scroll_trigger_width(FIXTURE_TEXT) == 30.0
    assert i.read_view_scroll_delay_ms(FIXTURE_TEXT) == 100.0
    assert i.read_view_scroll_max_speed(FIXTURE_TEXT) == 1500.0
    new_text = i.write_view_scroll_max_speed(FIXTURE_TEXT, 2000.0)
    assert i.read_view_scroll_max_speed(new_text) == 2000.0
    # sibling block untouched
    assert i.read_workspace_switch_max_speed(new_text) == 1500.0


def test_dnd_edge_workspace_switch_fields():
    assert i.read_workspace_switch_trigger_height(FIXTURE_TEXT) == 50.0
    assert i.read_workspace_switch_delay_ms(FIXTURE_TEXT) == 100.0
    assert i.read_workspace_switch_max_speed(FIXTURE_TEXT) == 1500.0


def test_hot_corners_roundtrip():
    assert i.read_hot_corner(FIXTURE_TEXT, "bottom-right") is True
    assert i.read_hot_corner(FIXTURE_TEXT, "top-left") is False
    new_text = i.write_hot_corner(FIXTURE_TEXT, "top-left", True)
    assert i.read_hot_corner(new_text, "top-left") is True
    assert i.read_hot_corner(new_text, "bottom-right") is True
    new_text2 = i.write_hot_corner(new_text, "bottom-right", False)
    assert i.read_hot_corner(new_text2, "bottom-right") is False
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest scripts/niri_config/tests/test_inputs.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.niri_config.inputs'`

- [ ] **Step 3: Implement `inputs.py`**

```python
# scripts/niri_config/inputs.py
"""Read/write fields in inputs.kdl's touchpad/mouse/trackpoint/gestures blocks."""
from . import kdl_edit as k

_TOUCHPAD = r'touchpad\s*\{'
_MOUSE = r'mouse\s*\{'
_TRACKPOINT = r'trackpoint\s*\{'
_GESTURES = r'gestures\s*\{'
_VIEW_SCROLL = r'dnd-edge-view-scroll\s*\{'
_WORKSPACE_SWITCH = r'dnd-edge-workspace-switch\s*\{'
_HOT_CORNERS = r'hot-corners\s*\{'


def read_touchpad_tap(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _TOUCHPAD), "tap")


def write_touchpad_tap(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _TOUCHPAD), "tap", enabled)


def read_touchpad_natural_scroll(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _TOUCHPAD), "natural-scroll")


def write_touchpad_natural_scroll(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _TOUCHPAD), "natural-scroll", enabled)


def read_touchpad_scroll_method(text: str) -> str | None:
    return k.read_string(text, k.find_block(text, _TOUCHPAD), "scroll-method")


def write_touchpad_scroll_method(text: str, value: str) -> str:
    return k.write_string(text, k.find_block(text, _TOUCHPAD), "scroll-method", value)


def read_mouse_natural_scroll(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _MOUSE), "natural-scroll")


def write_mouse_natural_scroll(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _MOUSE), "natural-scroll", enabled)


def read_mouse_accel_speed(text: str) -> float | None:
    return k.read_number(text, k.find_block(text, _MOUSE), "accel-speed")


def write_mouse_accel_speed(text: str, value: float) -> str:
    return k.write_number(text, k.find_block(text, _MOUSE), "accel-speed", value)


def read_mouse_accel_profile(text: str) -> str | None:
    return k.read_string(text, k.find_block(text, _MOUSE), "accel-profile")


def write_mouse_accel_profile(text: str, value: str) -> str:
    return k.write_string(text, k.find_block(text, _MOUSE), "accel-profile", value)


def read_trackpoint_natural_scroll(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _TRACKPOINT), "natural-scroll")


def write_trackpoint_natural_scroll(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _TRACKPOINT), "natural-scroll", enabled)


def read_trackpoint_accel_speed(text: str) -> float | None:
    return k.read_number(text, k.find_block(text, _TRACKPOINT), "accel-speed")


def write_trackpoint_accel_speed(text: str, value: float) -> str:
    return k.write_number(text, k.find_block(text, _TRACKPOINT), "accel-speed", value)


def _view_scroll_span(text: str) -> tuple[int, int]:
    gestures = k.find_block(text, _GESTURES)
    return k.find_nested_block(text, gestures, _VIEW_SCROLL)


def _workspace_switch_span(text: str) -> tuple[int, int]:
    gestures = k.find_block(text, _GESTURES)
    return k.find_nested_block(text, gestures, _WORKSPACE_SWITCH)


def _hot_corners_span(text: str) -> tuple[int, int]:
    gestures = k.find_block(text, _GESTURES)
    return k.find_nested_block(text, gestures, _HOT_CORNERS)


def read_view_scroll_trigger_width(text: str) -> float | None:
    return k.read_number(text, _view_scroll_span(text), "trigger-width")


def write_view_scroll_trigger_width(text: str, value: float) -> str:
    return k.write_number(text, _view_scroll_span(text), "trigger-width", value)


def read_view_scroll_delay_ms(text: str) -> float | None:
    return k.read_number(text, _view_scroll_span(text), "delay-ms")


def write_view_scroll_delay_ms(text: str, value: float) -> str:
    return k.write_number(text, _view_scroll_span(text), "delay-ms", value)


def read_view_scroll_max_speed(text: str) -> float | None:
    return k.read_number(text, _view_scroll_span(text), "max-speed")


def write_view_scroll_max_speed(text: str, value: float) -> str:
    return k.write_number(text, _view_scroll_span(text), "max-speed", value)


def read_workspace_switch_trigger_height(text: str) -> float | None:
    return k.read_number(text, _workspace_switch_span(text), "trigger-height")


def write_workspace_switch_trigger_height(text: str, value: float) -> str:
    return k.write_number(text, _workspace_switch_span(text), "trigger-height", value)


def read_workspace_switch_delay_ms(text: str) -> float | None:
    return k.read_number(text, _workspace_switch_span(text), "delay-ms")


def write_workspace_switch_delay_ms(text: str, value: float) -> str:
    return k.write_number(text, _workspace_switch_span(text), "delay-ms", value)


def read_workspace_switch_max_speed(text: str) -> float | None:
    return k.read_number(text, _workspace_switch_span(text), "max-speed")


def write_workspace_switch_max_speed(text: str, value: float) -> str:
    return k.write_number(text, _workspace_switch_span(text), "max-speed", value)


def read_hot_corner(text: str, corner: str) -> bool:
    return k.read_flag(text, _hot_corners_span(text), corner)


def write_hot_corner(text: str, corner: str, enabled: bool) -> str:
    return k.write_flag(text, _hot_corners_span(text), corner, enabled)
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest scripts/niri_config/tests/test_inputs.py -v`
Expected: PASS (8 tests)

- [ ] **Step 5: Commit**

```bash
git add scripts/niri_config/inputs.py scripts/niri_config/tests/test_inputs.py
git commit -m "feat(niri_config): add inputs.kdl field read/write"
```

---

### Task 5: `decorations.py` — layout/animations/blur/cursor fields

**Files:**
- Create: `scripts/niri_config/decorations.py`
- Test: `scripts/niri_config/tests/test_decorations.py`

**Interfaces:**
- Consumes: `kdl_edit` primitives (Task 1).
- Produces: `read_gaps/write_gaps`, `read_always_center_single_column/write_always_center_single_column`, `read_center_focused_column/write_center_focused_column`, `read_focus_ring_enabled/write_focus_ring_enabled`, `read_focus_ring_width/write_focus_ring_width`, `read_border_enabled/write_border_enabled`, `read_shadow_enabled/write_shadow_enabled`, `read_shadow_softness/write_shadow_softness`, `read_shadow_spread/write_shadow_spread`, `read_shadow_offset/write_shadow_offset(text, x, y)`, `read_shadow_color/write_shadow_color`, `read_animations_enabled/write_animations_enabled`, `read_animation_duration_ms(text, name)/write_animation_duration_ms(text, name, value)` where `name` is one of `workspace-switch`/`window-open`/`window-close`/`screenshot-ui-open`, `read_blur_enabled/write_blur_enabled`, `read_blur_passes/write_blur_passes`, `read_blur_offset/write_blur_offset`, `read_blur_noise/write_blur_noise`, `read_blur_saturation/write_blur_saturation`, `read_cursor_theme/write_cursor_theme`, `read_cursor_size/write_cursor_size`. Consumed by Task 6 (CLI) and Task 10 (Appearance tab).

- [ ] **Step 1: Write the failing tests**

```python
# scripts/niri_config/tests/test_decorations.py
from pathlib import Path
from scripts.niri_config import decorations as d

FIXTURE_TEXT = (Path(__file__).parent / "fixtures" / "decorations.kdl").read_text()


def test_gaps_roundtrip():
    assert d.read_gaps(FIXTURE_TEXT) == 10.0
    new_text = d.write_gaps(FIXTURE_TEXT, 16.0)
    assert d.read_gaps(new_text) == 16.0


def test_always_center_single_column():
    assert d.read_always_center_single_column(FIXTURE_TEXT) is True
    new_text = d.write_always_center_single_column(FIXTURE_TEXT, False)
    assert d.read_always_center_single_column(new_text) is False


def test_center_focused_column():
    assert d.read_center_focused_column(FIXTURE_TEXT) == "never"
    new_text = d.write_center_focused_column(FIXTURE_TEXT, "always")
    assert d.read_center_focused_column(new_text) == "always"


def test_focus_ring():
    assert d.read_focus_ring_enabled(FIXTURE_TEXT) is True
    assert d.read_focus_ring_width(FIXTURE_TEXT) == 2.0
    new_text = d.write_focus_ring_enabled(FIXTURE_TEXT, False)
    new_text = d.write_focus_ring_width(new_text, 4.0)
    assert d.read_focus_ring_enabled(new_text) is False
    assert d.read_focus_ring_width(new_text) == 4.0


def test_border_enabled():
    assert d.read_border_enabled(FIXTURE_TEXT) is False
    new_text = d.write_border_enabled(FIXTURE_TEXT, True)
    assert d.read_border_enabled(new_text) is True


def test_shadow_fields():
    assert d.read_shadow_enabled(FIXTURE_TEXT) is True
    assert d.read_shadow_softness(FIXTURE_TEXT) == 30.0
    assert d.read_shadow_spread(FIXTURE_TEXT) == 5.0
    assert d.read_shadow_offset(FIXTURE_TEXT) == (0.0, 5.0)
    assert d.read_shadow_color(FIXTURE_TEXT) == "#50505066"
    new_text = d.write_shadow_softness(FIXTURE_TEXT, 40.0)
    new_text = d.write_shadow_offset(new_text, 0.0, 8.0)
    new_text = d.write_shadow_color(new_text, "#00000080")
    assert d.read_shadow_softness(new_text) == 40.0
    assert d.read_shadow_offset(new_text) == (0.0, 8.0)
    assert d.read_shadow_color(new_text) == "#00000080"


def test_animations_enabled_and_durations():
    assert d.read_animations_enabled(FIXTURE_TEXT) is True
    assert d.read_animation_duration_ms(FIXTURE_TEXT, "workspace-switch") == 500.0
    assert d.read_animation_duration_ms(FIXTURE_TEXT, "window-open") == 400.0
    assert d.read_animation_duration_ms(FIXTURE_TEXT, "window-close") == 200.0
    assert d.read_animation_duration_ms(FIXTURE_TEXT, "screenshot-ui-open") == 200.0
    new_text = d.write_animation_duration_ms(FIXTURE_TEXT, "window-open", 250.0)
    assert d.read_animation_duration_ms(new_text, "window-open") == 250.0
    # sibling untouched
    assert d.read_animation_duration_ms(new_text, "window-close") == 200.0
    off = d.write_animations_enabled(FIXTURE_TEXT, False)
    assert d.read_animations_enabled(off) is False


def test_blur_fields():
    assert d.read_blur_passes(FIXTURE_TEXT) == 3.0
    assert d.read_blur_offset(FIXTURE_TEXT) == 3.0
    assert d.read_blur_noise(FIXTURE_TEXT) == 0.02
    assert d.read_blur_saturation(FIXTURE_TEXT) == 1.5
    assert d.read_blur_enabled(FIXTURE_TEXT) is None  # only commented `// off` present
    new_text = d.write_blur_enabled(FIXTURE_TEXT, False)
    assert d.read_blur_enabled(new_text) is False
    assert d.read_blur_passes(new_text) == 3.0  # untouched


def test_cursor_fields():
    assert d.read_cursor_theme(FIXTURE_TEXT) == "Bibata-Modern-Classic"
    assert d.read_cursor_size(FIXTURE_TEXT) == 24.0
    new_text = d.write_cursor_theme(FIXTURE_TEXT, "Adwaita")
    new_text = d.write_cursor_size(new_text, 32.0)
    assert d.read_cursor_theme(new_text) == "Adwaita"
    assert d.read_cursor_size(new_text) == 32.0
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest scripts/niri_config/tests/test_decorations.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'scripts.niri_config.decorations'`

- [ ] **Step 3: Implement `decorations.py`**

```python
# scripts/niri_config/decorations.py
"""Read/write fields in decorations.kdl's layout/animations/blur/cursor blocks."""
from . import kdl_edit as k

_LAYOUT = r'layout\s*\{'
_FOCUS_RING = r'focus-ring\s*\{'
_BORDER = r'border\s*\{'
_SHADOW = r'shadow\s*\{'
_ANIMATIONS = r'animations\s*\{'
_BLUR = r'blur\s*\{'
_CURSOR = r'cursor\s*\{'


def _layout_span(text: str) -> tuple[int, int]:
    return k.find_block(text, _LAYOUT)


def _focus_ring_span(text: str) -> tuple[int, int]:
    return k.find_nested_block(text, _layout_span(text), _FOCUS_RING)


def _border_span(text: str) -> tuple[int, int]:
    return k.find_nested_block(text, _layout_span(text), _BORDER)


def _shadow_span(text: str) -> tuple[int, int]:
    return k.find_nested_block(text, _layout_span(text), _SHADOW)


def read_gaps(text: str) -> float | None:
    return k.read_number(text, _layout_span(text), "gaps")


def write_gaps(text: str, value: float) -> str:
    return k.write_number(text, _layout_span(text), "gaps", value)


def read_always_center_single_column(text: str) -> bool | None:
    return k.read_bool_kv(text, _layout_span(text), "always-center-single-column")


def write_always_center_single_column(text: str, value: bool) -> str:
    return k.write_bool_kv(text, _layout_span(text), "always-center-single-column", value)


def read_center_focused_column(text: str) -> str | None:
    return k.read_string(text, _layout_span(text), "center-focused-column")


def write_center_focused_column(text: str, value: str) -> str:
    return k.write_string(text, _layout_span(text), "center-focused-column", value)


def read_focus_ring_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _focus_ring_span(text))


def write_focus_ring_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _focus_ring_span(text), value)


def read_focus_ring_width(text: str) -> float | None:
    return k.read_number(text, _focus_ring_span(text), "width")


def write_focus_ring_width(text: str, value: float) -> str:
    return k.write_number(text, _focus_ring_span(text), "width", value)


def read_border_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _border_span(text))


def write_border_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _border_span(text), value)


def read_shadow_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _shadow_span(text))


def write_shadow_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _shadow_span(text), value)


def read_shadow_softness(text: str) -> float | None:
    return k.read_number(text, _shadow_span(text), "softness")


def write_shadow_softness(text: str, value: float) -> str:
    return k.write_number(text, _shadow_span(text), "softness", value)


def read_shadow_spread(text: str) -> float | None:
    return k.read_number(text, _shadow_span(text), "spread")


def write_shadow_spread(text: str, value: float) -> str:
    return k.write_number(text, _shadow_span(text), "spread", value)


def read_shadow_offset(text: str) -> tuple[float, float] | None:
    return k.read_named_args(text, _shadow_span(text), "offset", ["x", "y"])


def write_shadow_offset(text: str, x: float, y: float) -> str:
    return k.write_named_args(text, _shadow_span(text), "offset", ["x", "y"], [x, y])


def read_shadow_color(text: str) -> str | None:
    return k.read_string(text, _shadow_span(text), "color")


def write_shadow_color(text: str, value: str) -> str:
    return k.write_string(text, _shadow_span(text), "color", value)


def read_animations_enabled(text: str) -> bool | None:
    return k.read_on_off(text, k.find_block(text, _ANIMATIONS))


def write_animations_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, k.find_block(text, _ANIMATIONS), value)


def _animation_span(text: str, name: str) -> tuple[int, int]:
    animations = k.find_block(text, _ANIMATIONS)
    import re
    return k.find_nested_block(text, animations, re.escape(name) + r'\s*\{')


def read_animation_duration_ms(text: str, name: str) -> float | None:
    return k.read_number(text, _animation_span(text, name), "duration-ms")


def write_animation_duration_ms(text: str, name: str, value: float) -> str:
    return k.write_number(text, _animation_span(text, name), "duration-ms", value)


def _blur_span(text: str) -> tuple[int, int]:
    return k.find_block(text, _BLUR)


def read_blur_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _blur_span(text))


def write_blur_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _blur_span(text), value)


def read_blur_passes(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "passes")


def write_blur_passes(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "passes", value)


def read_blur_offset(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "offset")


def write_blur_offset(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "offset", value)


def read_blur_noise(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "noise")


def write_blur_noise(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "noise", value)


def read_blur_saturation(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "saturation")


def write_blur_saturation(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "saturation", value)


def _cursor_span(text: str) -> tuple[int, int]:
    return k.find_block(text, _CURSOR)


def read_cursor_theme(text: str) -> str | None:
    return k.read_string(text, _cursor_span(text), "xcursor-theme")


def write_cursor_theme(text: str, value: str) -> str:
    return k.write_string(text, _cursor_span(text), "xcursor-theme", value)


def read_cursor_size(text: str) -> float | None:
    return k.read_number(text, _cursor_span(text), "xcursor-size")


def write_cursor_size(text: str, value: float) -> str:
    return k.write_number(text, _cursor_span(text), "xcursor-size", value)
```

Note on `_blur_span`'s `find_block` matching `blur {`: the fixture's blur block has a commented `// off` as its first content line. `find_block` only looks for the *header* (`blur\s*\{`), which matches regardless of what's inside, so this works unchanged.

- [ ] **Step 4: Run tests to verify they pass**

Run: `python3 -m pytest scripts/niri_config/tests/test_decorations.py -v`
Expected: PASS (9 tests)

- [ ] **Step 5: Commit**

```bash
git add scripts/niri_config/decorations.py scripts/niri_config/tests/test_decorations.py
git commit -m "feat(niri_config): add decorations.kdl field read/write"
```

---

### Task 6: CLI entry point

**Files:**
- Create: `scripts/niri_config/__main__.py`
- Test: `scripts/niri_config/tests/test_cli.py`

**Interfaces:**
- Consumes: `outputs.py`, `inputs.py`, `decorations.py` (Tasks 3-5), `config_file.NiriConfigFile` (Task 2).
- Produces: `python3 -m scripts.niri_config <file> read <field> [<arg>...] [--path P]` prints the value to stdout and exits 0, or prints nothing and exits 1 if the field is absent/unreadable. `python3 -m scripts.niri_config <file> write <field> <value> [<arg>...] [--path P]` prints `OK` and exits 0 on success, or prints `ERROR: <message>` to stderr and exits 1 on failure. `<file>` is one of `outputs`/`inputs`/`decorations`. `--path` overrides the default `~/.config/niri/<file>.kdl` (used by tests to target fixtures; QML omits it). Fields needing an extra positional (`output`'s `<name>`, `animation`'s `<name>`, `hot-corner`'s `<corner>`) take it as the argument right after `<field>`. Consumed by Task 8 (QML `Process` calls).

- [ ] **Step 1: Write the failing tests**

```python
# scripts/niri_config/tests/test_cli.py
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


def test_decorations_gaps_roundtrip(tmp_path):
    target = tmp_path / "decorations.kdl"
    shutil.copy2(FIXTURES / "decorations.kdl", target)
    result = run_cli("decorations", "write", "gaps", "20", path=target)
    assert result.returncode == 0
    result2 = run_cli("decorations", "read", "gaps", path=target)
    assert result2.stdout.strip() == "20"
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `python3 -m pytest scripts/niri_config/tests/test_cli.py -v`
Expected: FAIL — `No module named scripts.niri_config.__main__` (or a non-zero/empty result from the subprocess)

- [ ] **Step 3: Implement `__main__.py`**

```python
# scripts/niri_config/__main__.py
import argparse
import os
import sys

from . import outputs as o
from . import inputs as i
from . import decorations as d
from .config_file import NiriConfigFile

DEFAULT_PATHS = {
    "outputs": os.path.expanduser("~/.config/niri/outputs.kdl"),
    "inputs": os.path.expanduser("~/.config/niri/inputs.kdl"),
    "decorations": os.path.expanduser("~/.config/niri/decorations.kdl"),
}

# field -> (read_fn, write_fn, value_type, needs_arg)
# read_fn(text, *args) -> value; write_fn(text, *args, value) -> new_text
_FIELDS = {
    "outputs": {
        "scale": (o.read_scale, o.write_scale, float, True),
        "transform": (o.read_transform, o.write_transform, str, True),
        "mode": (o.read_mode, o.write_mode, str, True),
    },
    "inputs": {
        "touchpad-tap": (i.read_touchpad_tap, i.write_touchpad_tap, bool, False),
        "touchpad-natural-scroll": (i.read_touchpad_natural_scroll, i.write_touchpad_natural_scroll, bool, False),
        "touchpad-scroll-method": (i.read_touchpad_scroll_method, i.write_touchpad_scroll_method, str, False),
        "mouse-natural-scroll": (i.read_mouse_natural_scroll, i.write_mouse_natural_scroll, bool, False),
        "mouse-accel-speed": (i.read_mouse_accel_speed, i.write_mouse_accel_speed, float, False),
        "mouse-accel-profile": (i.read_mouse_accel_profile, i.write_mouse_accel_profile, str, False),
        "trackpoint-natural-scroll": (i.read_trackpoint_natural_scroll, i.write_trackpoint_natural_scroll, bool, False),
        "trackpoint-accel-speed": (i.read_trackpoint_accel_speed, i.write_trackpoint_accel_speed, float, False),
        "view-scroll-trigger-width": (i.read_view_scroll_trigger_width, i.write_view_scroll_trigger_width, float, False),
        "view-scroll-delay-ms": (i.read_view_scroll_delay_ms, i.write_view_scroll_delay_ms, float, False),
        "view-scroll-max-speed": (i.read_view_scroll_max_speed, i.write_view_scroll_max_speed, float, False),
        "workspace-switch-trigger-height": (i.read_workspace_switch_trigger_height, i.write_workspace_switch_trigger_height, float, False),
        "workspace-switch-delay-ms": (i.read_workspace_switch_delay_ms, i.write_workspace_switch_delay_ms, float, False),
        "workspace-switch-max-speed": (i.read_workspace_switch_max_speed, i.write_workspace_switch_max_speed, float, False),
        "hot-corner": (i.read_hot_corner, i.write_hot_corner, bool, True),
    },
    "decorations": {
        "gaps": (d.read_gaps, d.write_gaps, float, False),
        "always-center-single-column": (d.read_always_center_single_column, d.write_always_center_single_column, bool, False),
        "center-focused-column": (d.read_center_focused_column, d.write_center_focused_column, str, False),
        "focus-ring-enabled": (d.read_focus_ring_enabled, d.write_focus_ring_enabled, bool, False),
        "focus-ring-width": (d.read_focus_ring_width, d.write_focus_ring_width, float, False),
        "border-enabled": (d.read_border_enabled, d.write_border_enabled, bool, False),
        "shadow-enabled": (d.read_shadow_enabled, d.write_shadow_enabled, bool, False),
        "shadow-softness": (d.read_shadow_softness, d.write_shadow_softness, float, False),
        "shadow-spread": (d.read_shadow_spread, d.write_shadow_spread, float, False),
        "shadow-color": (d.read_shadow_color, d.write_shadow_color, str, False),
        "animations-enabled": (d.read_animations_enabled, d.write_animations_enabled, bool, False),
        "animation-duration-ms": (d.read_animation_duration_ms, d.write_animation_duration_ms, float, True),
        "blur-enabled": (d.read_blur_enabled, d.write_blur_enabled, bool, False),
        "blur-passes": (d.read_blur_passes, d.write_blur_passes, float, False),
        "blur-offset": (d.read_blur_offset, d.write_blur_offset, float, False),
        "blur-noise": (d.read_blur_noise, d.write_blur_noise, float, False),
        "blur-saturation": (d.read_blur_saturation, d.write_blur_saturation, float, False),
        "cursor-theme": (d.read_cursor_theme, d.write_cursor_theme, str, False),
        "cursor-size": (d.read_cursor_size, d.write_cursor_size, float, False),
    },
}


def _parse_value(raw: str, value_type):
    if value_type is bool:
        return raw.lower() in ("1", "true", "on", "yes")
    return value_type(raw)


def _format_value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(prog="niri_config")
    parser.add_argument("file", choices=list(_FIELDS.keys()))
    parser.add_argument("action", choices=["read", "write"])
    parser.add_argument("field")
    parser.add_argument("rest", nargs="*")
    parser.add_argument("--path", default=None)
    args = parser.parse_args(argv)

    fields = _FIELDS[args.file]
    if args.field not in fields:
        print(f"ERROR: unknown field {args.field!r} for {args.file}", file=sys.stderr)
        return 1
    read_fn, write_fn, value_type, needs_arg = fields[args.field]
    path = args.path or DEFAULT_PATHS[args.file]

    if args.action == "read":
        extra = list(args.rest)
        cfg = NiriConfigFile(path)
        try:
            value = read_fn(cfg.read_text(), *extra)
        except ValueError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            return 1
        if value is None:
            return 1
        print(_format_value(value))
        return 0

    # write: rest = [value, *extra_args] if needs_arg else [value]
    if not args.rest:
        print("ERROR: missing value", file=sys.stderr)
        return 1
    raw_value, *extra = args.rest
    value = _parse_value(raw_value, value_type)

    cfg = NiriConfigFile(path)
    result = cfg.apply(lambda text: write_fn(text, *extra, value))
    if not result.ok:
        print(f"ERROR: {result.error}", file=sys.stderr)
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
```

Note on argument order for `hot-corner` and `animation-duration-ms`, the two fields with an extra positional (`corner`/`name`): reads take it as `<field> <extra-arg>` (e.g. `read hot-corner top-left`), writes take it as `<field> <value> <extra-arg>` (e.g. `write hot-corner true top-left`). `main()`'s write path (`raw_value, *extra = args.rest`) already produces `extra=["top-left"]` and calls `write_fn(text, *extra, value)` = `write_hot_corner(text, "top-left", True)`, which matches that function's `(text, corner, enabled)` signature — no special-casing needed. The two tests below just lock this in as a regression test.

- [ ] **Step 4: Add two regression tests locking in the extra-positional argument order**

```python
# append to scripts/niri_config/tests/test_cli.py

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
```

Run: `python3 -m pytest scripts/niri_config/tests/test_cli.py -v`
Expected: PASS (8 tests) — per the note above, `main()` already handles this argument order correctly, so this step should pass without changes.

- [ ] **Step 5: Commit**

```bash
git add scripts/niri_config/__main__.py scripts/niri_config/tests/test_cli.py
git commit -m "feat(niri_config): add CLI entry point for read/write dispatch"
```

---

### Task 7: QML remote-setting primitives

**Files:**
- Create: `bar/primitives/RemoteSwitchRow.qml`
- Create: `bar/primitives/RemoteSliderRow.qml`
- Create: `bar/primitives/RemoteTextRow.qml`

**Interfaces:**
- Consumes: `ListItem.qml`, `SwitchControl.qml`, `SliderControl.qml`, `TextFieldControl.qml` (all existing primitives), and the CLI from Task 6 via `Quickshell.Io.Process`.
- Produces: three components each taking `readArgs: list<string>` (args after `python3 -m scripts.niri_config <file> read`), `writeArgs: list<string>` (args after `... write`, value appended automatically), `leadingIcon`, `title`, `subtitle`, plus per-kind value props. Emits `writeFailed(string message)`. Consumed by Task 8 (`DisplayInputTab.qml`) and Task 10 (`AppearanceTab.qml`'s Window Manager section).

- [ ] **Step 1: Implement `RemoteSwitchRow.qml`**

```qml
// bar/primitives/RemoteSwitchRow.qml
// ListItem + SwitchControl backed by a niri_config CLI field. Reads the
// current value once when the row becomes visible; every toggle writes
// through the CLI and reverts the control if the write fails.
import QtQuick
import Quickshell.Io
import "../../config"

ListItem {
  id: root

  property string cliFile: ""       // "outputs" | "inputs" | "decorations"
  property string cliField: ""      // e.g. "touchpad-tap"
  property var extraArgs: []         // e.g. ["eDP-1"] for per-output fields
  property bool checked: false
  property string statusMessage: ""
  signal writeFailed(string message)

  height: 60
  Layout.fillWidth: true

  SwitchControl {
    checked: root.checked
    activeColor: Colors.primary
    surfaceContainerHigh: Colors.surfaceContainerHigh
    surfaceContainerHighest: Colors.surfaceContainerHighest
    outline: Colors.styleOutlineStrong
    motionDuration: Config.motionMedium
    reducedMotion: Config.reducedMotion
    accessibleName: root.title
    onToggled: root.setValue(!root.checked)
  }

  Process {
    id: readProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var v = text.trim().toLowerCase()
        if (v === "true" || v === "false") root.checked = (v === "true")
      }
    }
  }

  Process {
    id: writeProc
    running: false
    property bool pendingValue: false
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") {
          root.checked = !writeProc.pendingValue
          root.statusMessage = text.trim()
          root.writeFailed(text.trim())
        }
      }
    }
  }

  function reload() {
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function setValue(value) {
    root.checked = value
    writeProc.pendingValue = value
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, value ? "true" : "false"].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  Component.onCompleted: root.reload()
}
```

- [ ] **Step 2: Implement `RemoteSliderRow.qml`**

```qml
// bar/primitives/RemoteSliderRow.qml
// Label + SliderControl backed by a niri_config CLI field, for a bounded
// numeric range. `min`/`max` define the slider's real-value range;
// `unit` is cosmetic display text (e.g. "px", "ms", "%").
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"

RowLayout {
  id: root

  property string cliFile: ""
  property string cliField: ""
  property var extraArgs: []
  property string label: ""
  property real min: 0
  property real max: 100
  property real value: min
  property string unit: ""
  property int decimals: 0
  signal writeFailed(string message)

  Layout.fillWidth: true
  spacing: Config.spacingMedium

  Text {
    text: root.label
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.textBodySize
    Layout.preferredWidth: 120
  }

  SliderControl {
    id: slider
    Layout.fillWidth: true
    value: root.max > root.min ? (root.value - root.min) / (root.max - root.min) : 0
    stepSize: root.max > root.min ? 1 / (root.max - root.min) : 0.01
    accessibleMinimumValue: root.min
    accessibleMaximumValue: root.max
    accessibleUnit: root.unit
    activeColor: Colors.primary
    surfaceContainerHigh: Colors.surfaceContainerHigh
    surfaceContainerHighest: Colors.surfaceContainerHighest
    outline: Colors.styleOutlineStrong
    focusColor: Colors.primary
    motionDuration: Config.motionMedium
    reducedMotion: Config.reducedMotion
    accessibleName: root.label
    onChanged: function(val) {
      root.value = root.min + val * (root.max - root.min)
    }
    onInteractionFinished: root.commit()
  }

  Text {
    text: root.decimals > 0 ? root.value.toFixed(root.decimals) + root.unit : Math.round(root.value) + root.unit
    color: Colors.fgSurface
    font.family: Config.fontFamily
    font.pixelSize: 11
    Layout.preferredWidth: 50
  }

  Process {
    id: readProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var v = parseFloat(text.trim())
        if (!isNaN(v)) root.value = v
      }
    }
  }

  Process {
    id: writeProc
    running: false
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") root.writeFailed(text.trim())
      }
    }
  }

  function reload() {
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function commit() {
    var formatted = root.decimals > 0 ? root.value.toFixed(root.decimals) : String(Math.round(root.value))
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, formatted].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  Component.onCompleted: root.reload()
}
```

- [ ] **Step 3: Implement `RemoteTextRow.qml`**

```qml
// bar/primitives/RemoteTextRow.qml
// Label + TextFieldControl backed by a niri_config CLI field, for string
// values (e.g. cursor theme name). Commits on Enter or on losing focus.
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import "../../config"

RowLayout {
  id: root

  property string cliFile: ""
  property string cliField: ""
  property var extraArgs: []
  property string label: ""
  property string value: ""
  signal writeFailed(string message)

  Layout.fillWidth: true
  spacing: Config.spacingMedium

  Text {
    text: root.label
    color: Colors.fgSurfaceVariant
    font.family: Config.fontFamily
    font.pixelSize: Config.textBodySize
    Layout.preferredWidth: 120
  }

  TextFieldControl {
    id: field
    Layout.fillWidth: true
    text: root.value
    accessibleName: root.label
    onAccepted: root.commit(text)
    input.onActiveFocusChanged: {
      if (!input.activeFocus) root.commit(field.text)
    }
  }

  Process {
    id: readProc
    running: false
    stdout: StdioCollector {
      onStreamFinished: {
        var v = text.trim()
        if (v !== "") { root.value = v; field.text = v }
      }
    }
  }

  Process {
    id: writeProc
    running: false
    stderr: StdioCollector {
      onStreamFinished: {
        if (text.trim() !== "") root.writeFailed(text.trim())
      }
    }
  }

  function reload() {
    readProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "read", root.cliField].concat(root.extraArgs)
    readProc.running = false
    readProc.running = true
  }

  function commit(newValue) {
    if (newValue === root.value) return
    root.value = newValue
    writeProc.command = ["python3", "-m", "scripts.niri_config", root.cliFile, "write", root.cliField, newValue].concat(root.extraArgs)
    writeProc.running = false
    writeProc.running = true
  }

  Component.onCompleted: root.reload()
}
```

- [ ] **Step 4: Lint all three files**

Run: `qmllint bar/primitives/RemoteSwitchRow.qml bar/primitives/RemoteSliderRow.qml bar/primitives/RemoteTextRow.qml`
Expected: no output (clean). Fix any reported issue before moving on — these three files have no automated test coverage of their own, so a clean lint plus the manual verification in Task 11 is what stands in for testing here.

- [ ] **Step 5: Commit**

```bash
git add bar/primitives/RemoteSwitchRow.qml bar/primitives/RemoteSliderRow.qml bar/primitives/RemoteTextRow.qml
git commit -m "feat(settings): add reusable Process-backed remote setting rows"
```

---

### Task 8: `DisplayInputTab.qml` — Outputs + Input sections

**Files:**
- Create: `bar/settings/DisplayInputTab.qml`

**Interfaces:**
- Consumes: `RemoteSwitchRow`/`RemoteSliderRow`/`RemoteTextRow` (Task 7), `StyledSurface` primitive (existing), `root.currentTab` and `root.compactLayout` from `SettingsPanel.qml` (existing pattern, see `GeneralTab.qml`'s `property QtObject root: null`).
- Produces: a `Flickable` component with `property QtObject root: null` and `visible: root.currentTab === 11`, following the exact shape of every existing tab file. Consumed by Task 9 (`SettingsPanel.qml` wiring).

- [ ] **Step 1: Implement `DisplayInputTab.qml`**

```qml
// bar/settings/DisplayInputTab.qml
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"
import "../primitives"
import "../../config"

Flickable {
  id: displayInputTab
  property QtObject root: null
  readonly property bool compactLayout: root ? root.compactLayout : false
  anchors.fill: parent
  visible: root.currentTab === 11
  clip: true
  contentWidth: width
  contentHeight: mainColumn.implicitHeight
  interactive: contentHeight > height
  boundsBehavior: Flickable.StopAtBounds

  property string statusMessage: ""

  function onFieldFailed(message) {
    displayInputTab.statusMessage = message
  }

  Process {
    id: listOutputsProc
    command: ["niri", "msg", "-j", "outputs"]
    running: displayInputTab.visible
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var parsed = JSON.parse(text)
          var names = Object.keys(parsed)
          outputsRepeater.model = names
        } catch (e) {
          outputsRepeater.model = ["eDP-1"]  // fallback so the UI still renders something
        }
      }
    }
  }

  ColumnLayout {
    id: mainColumn
    width: displayInputTab.width
    spacing: Config.spacingLarge

    Text {
      text: "Outputs"
      color: Colors.fgSurface
      font.family: Config.fontFamily
      font.pixelSize: Config.textTitleSize
      font.weight: Font.Bold
    }

    Repeater {
      id: outputsRepeater
      model: []

      delegate: StyledSurface {
        required property string modelData
        Layout.fillWidth: true
        Layout.preferredHeight: outputColumn.implicitHeight + 24
        radius: Config.shapeLarge
        surfaceColor: Colors.surfaceContainer
        outlineColor: Colors.styleOutline
        outlineWidth: Config.themeBorderWidth

        ColumnLayout {
          id: outputColumn
          anchors.fill: parent
          anchors.margins: 12
          spacing: Config.spacingSmall

          Text {
            text: modelData
            color: Colors.fgSurface
            font.family: Config.fontFamily
            font.pixelSize: Config.textBodyLargeSize
            font.weight: Font.Medium
          }

          RemoteTextRow {
            Layout.fillWidth: true
            cliFile: "outputs"; cliField: "mode"; extraArgs: [modelData]
            label: "Mode"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteSliderRow {
            Layout.fillWidth: true
            cliFile: "outputs"; cliField: "scale"; extraArgs: [modelData]
            label: "Scale"; min: 0.5; max: 3.0; decimals: 2
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
          RemoteTextRow {
            Layout.fillWidth: true
            cliFile: "outputs"; cliField: "transform"; extraArgs: [modelData]
            label: "Transform (normal/90/180/270)"
            onWriteFailed: displayInputTab.onFieldFailed(message)
          }
        }
      }
    }

    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: inputColumn.implicitHeight + 24
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: inputColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: Config.spacingSmall

        Text {
          text: "Touchpad"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
        }

        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "touchpad-tap"
          leadingIcon: "touch_app"; title: "Tap to click"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "touchpad-natural-scroll"
          leadingIcon: "swap_vert"; title: "Natural scroll"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteTextRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "touchpad-scroll-method"
          label: "Scroll method (two-finger/edge)"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }

        Text {
          text: "Mouse"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.topMargin: 8
        }

        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "mouse-natural-scroll"
          leadingIcon: "mouse"; title: "Natural scroll"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "mouse-accel-speed"
          label: "Accel speed"; min: -1.0; max: 1.0; decimals: 2
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }

        Text {
          text: "Trackpoint"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.topMargin: 8
        }

        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "trackpoint-natural-scroll"
          leadingIcon: "mouse"; title: "Natural scroll"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "trackpoint-accel-speed"
          label: "Accel speed"; min: -1.0; max: 1.0; decimals: 2
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }

        Text {
          text: "Edge gestures"
          color: Colors.fgSurfaceVariant
          font.family: Config.fontFamily
          font.pixelSize: Config.textCaptionSize
          font.weight: Font.Medium
          Layout.topMargin: 8
        }

        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "view-scroll-max-speed"
          label: "View-scroll max speed"; min: 200; max: 4000; unit: "px/s"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "inputs"; cliField: "workspace-switch-max-speed"
          label: "Workspace-switch max speed"; min: 200; max: 4000; unit: "px/s"
          onWriteFailed: displayInputTab.onFieldFailed(message)
        }
      }
    }

    Text {
      visible: displayInputTab.statusMessage !== ""
      Layout.fillWidth: true
      text: displayInputTab.statusMessage
      color: Colors.destructive
      font.family: Config.fontFamily
      font.pixelSize: Config.fontPixelSize
      wrapMode: Text.WordWrap
    }
  }
}
```

This covers the highest-value fields from the inventory (not literally every one of the 18 input fields — `mouse-accel-profile`, the two `dnd-edge-*` trigger-width/height/delay-ms fields, and all four `hot-corner`s are left for a fast-follow once this pattern is confirmed working end-to-end in Task 11; they're mechanically identical additions using the same three row components).

- [ ] **Step 2: Lint**

Run: `qmllint bar/settings/DisplayInputTab.qml`
Expected: no output. Fix any reported issue.

- [ ] **Step 3: Commit**

```bash
git add bar/settings/DisplayInputTab.qml
git commit -m "feat(settings): add Display & Input tab (outputs + touchpad/mouse/trackpoint)"
```

---

### Task 9: Wire the new tab into `SettingsPanel.qml`

**Files:**
- Modify: `bar/SettingsPanel.qml`

**Interfaces:**
- Consumes: `DisplayInputTab` (Task 8).
- Produces: sidebar entry, `tabContainer` child, updated `currentTab` bound, updated `searchEntries`. Nothing later depends on this task's internals.

This task deliberately **appends** the new tab at the end of the existing list (index 11, after Shortcuts) rather than inserting it after Wallpaper as originally sketched in the spec's UI section — inserting in the middle would require renumbering `visible: root.currentTab === N` in all seven tab files from Network onward, plus `statsTimer`'s `root.currentTab === 9` check and the tab-numbers in `searchEntries`, for a purely cosmetic ordering difference. Appending avoids touching any of those seven unrelated, already-working files.

- [ ] **Step 1: Bump the tab count bound**

In `bar/SettingsPanel.qml`, find:

```qml
  property int currentTab: Math.max(0, Math.min(10, Settings.lastSettingsTab))
```

Replace with:

```qml
  property int currentTab: Math.max(0, Math.min(11, Settings.lastSettingsTab))
```

- [ ] **Step 2: Add the sidebar entry**

Find the `tabRepeater`'s `model:` array (ends with `{ icon: "keyboard", label: "Shortcuts" }`) and add a new last entry:

```qml
                  { icon: "keyboard", label: "Shortcuts" },
                  { icon: "monitor", label: "Display & Input" }
```

(Note the trailing comma added after the `"Shortcuts"` entry, matching normal JS array syntax.)

- [ ] **Step 3: Add the tab component**

Find the last tab component in `tabContainer` (`SystemTab { root: root }` before the closing braces) and add, right after it:

```qml
          SystemTab {
            root: root
          }

          DisplayInputTab {
            root: root
          }
```

- [ ] **Step 4: Add search index entries**

In `searchEntries` (near the top of the file), add before the closing `]`:

```qml
    { tab: 11, icon: "monitor", title: "Display scale", subtitle: "Display & Input · Outputs" },
    { tab: 11, icon: "screen_rotation", title: "Display transform", subtitle: "Display & Input · Outputs" },
    { tab: 11, icon: "touch_app", title: "Tap to click", subtitle: "Display & Input · Touchpad" },
    { tab: 11, icon: "swap_vert", title: "Natural scroll", subtitle: "Display & Input · Touchpad, mouse, trackpoint" },
    { tab: 11, icon: "mouse", title: "Pointer accel speed", subtitle: "Display & Input · Mouse, trackpoint" }
```

- [ ] **Step 5: Lint and reload**

Run: `qmllint bar/SettingsPanel.qml`
Expected: no output.

Then confirm the running shell hot-reloads without error: `journalctl --user -u quickshell.service -n 5 --no-pager` after saving, expect `Configuration Loaded` with no warnings/errors in between.

- [ ] **Step 6: Manual visual check**

Run: `qs ipc call shell settings` (toggles the panel open), then `grim -o eDP-1 /tmp/settings-check.png` and view the screenshot. Confirm "Display & Input" appears as the last sidebar entry and clicking it shows the Outputs/Touchpad/Mouse/Trackpoint sections from Task 8.

- [ ] **Step 7: Commit**

```bash
git add bar/SettingsPanel.qml
git commit -m "feat(settings): wire Display & Input tab into the sidebar and search index"
```

---

### Task 10: Decorations section in `AppearanceTab.qml`

**Files:**
- Modify: `bar/settings/AppearanceTab.qml`

**Interfaces:**
- Consumes: `RemoteSwitchRow`/`RemoteSliderRow` (Task 7), `decorations.py`'s CLI field names (Task 5/6, via the `_FIELDS["decorations"]` keys already wired in Task 6 — `gaps`, `focus-ring-enabled`, `border-enabled`, `shadow-enabled`, `animations-enabled`, `blur-enabled`, `blur-passes`, `cursor-theme`, `cursor-size`).
- Produces: nothing later depends on this.

- [ ] **Step 1: Add the "Window Manager" section**

`AppearanceTab.qml` already imports `"../primitives"` (confirm this import exists near the top of the file; if not, add `import "../primitives"` alongside the file's other imports). Find the end of the existing Sizing `StyledSurface` block (the one containing the "Bar Size" slider, near the end of `mainColumn`) and add a new sibling `StyledSurface` right after it, before `mainColumn`'s closing brace:

```qml
    // Niri window manager (gaps, animations, blur, cursor)
    StyledSurface {
      Layout.fillWidth: true
      Layout.preferredHeight: wmColumn.implicitHeight + 24
      radius: Config.shapeLarge
      surfaceColor: Colors.surfaceContainer
      outlineColor: Colors.styleOutline
      outlineWidth: Config.themeBorderWidth

      ColumnLayout {
        id: wmColumn
        anchors.fill: parent
        anchors.margins: 12
        spacing: Config.spacingSmall

        Text {
          text: "Window Manager"
          color: Colors.fgSurface
          font.family: Config.fontFamily
          font.pixelSize: Config.textTitleSize
          font.weight: Font.Bold
        }

        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "gaps"
          label: "Gaps"; min: 0; max: 32; unit: "px"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "focus-ring-enabled"
          leadingIcon: "crop_free"; title: "Focus ring"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "border-enabled"
          leadingIcon: "crop_din"; title: "Window border"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "shadow-enabled"
          leadingIcon: "blur_on"; title: "Window shadow"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "animations-enabled"
          leadingIcon: "animation"; title: "Animations"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSwitchRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "blur-enabled"
          leadingIcon: "lens_blur"; title: "Background blur"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "blur-passes"
          label: "Blur passes"; min: 1; max: 5
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }
        RemoteSliderRow {
          Layout.fillWidth: true
          cliFile: "decorations"; cliField: "cursor-size"
          label: "Cursor size"; min: 16; max: 48; unit: "px"
          onWriteFailed: appearanceTab.onWmFieldFailed(message)
        }

        Text {
          visible: appearanceTab.wmStatusMessage !== ""
          Layout.fillWidth: true
          text: appearanceTab.wmStatusMessage
          color: Colors.destructive
          font.family: Config.fontFamily
          font.pixelSize: Config.fontPixelSize
          wrapMode: Text.WordWrap
        }
      }
    }
```

Also add, near the top of the file alongside `AppearanceTab`'s other `property`/`function` declarations (the file's root `id` — confirm the exact `id:` by reading the top of `AppearanceTab.qml`, it was not `appearanceTab` in every reference seen so far, so match whatever the file actually uses):

```qml
  property string wmStatusMessage: ""
  function onWmFieldFailed(message) {
    wmStatusMessage = message
  }
```

(Left as read-the-file-first because this task modifies an existing 26KB file rather than creating a new one — confirm the root `id:` and the exact insertion point by reading `bar/settings/AppearanceTab.qml` in full before editing, rather than assuming line numbers that may have drifted.)

- [ ] **Step 2: Lint**

Run: `qmllint bar/settings/AppearanceTab.qml`
Expected: no output.

- [ ] **Step 3: Manual visual check**

Reload the running shell, open Settings → Appearance, scroll to the bottom, confirm the new "Window Manager" section renders with all 8 rows showing real values read from `decorations.kdl`.

- [ ] **Step 4: Commit**

```bash
git add bar/settings/AppearanceTab.qml
git commit -m "feat(settings): add Window Manager section to Appearance tab"
```

---

### Task 11: End-to-end live verification

**Files:** none (verification only)

This task must be run interactively with the user aware it's happening, since — unlike every earlier task — it touches the real `~/.config/niri/*.kdl` files. Do not run this unattended.

- [ ] **Step 1: Confirm live reload behavior**

With the user's go-ahead, edit one harmless field through the new UI (e.g. toggle "Window shadow" off and back on in Appearance → Window Manager) and observe whether niri picks up the change without a manual restart. If it does not, the fix is in `config_file.py`'s `apply()`: after a successful `os.replace`, also update `~/.config/niri/config.kdl`'s mtime (e.g. `Path(...).touch()`) so niri's own file watcher notices — add that line, re-test, and add a regression test to `test_config_file.py` asserting `config.kdl`'s mtime advances after a successful `apply()` on `outputs.kdl`.

- [ ] **Step 2: Confirm the error path**

Temporarily set an invalid value through the UI if possible (e.g. type "not-a-number" into a slider's — there's no free-text number entry in this UI, so instead verify the error path via the CLI directly: `python3 -m scripts.niri_config outputs write scale not-a-number eDP-1`, expect a non-zero exit and an `ERROR:` message, and confirm `~/.config/niri/outputs.kdl` is byte-for-byte unchanged afterward).

- [ ] **Step 3: Confirm backups**

`ls ~/.config/niri/.backups/` — confirm files appear there after the Step 1 toggle, named `<file>.<timestamp>.kdl`.

- [ ] **Step 4: Report to the user**

Summarize what was verified, any fix applied in Step 1, and explicitly call out the fields left out of Tasks 8/10 (deferred per those tasks' notes) as known follow-up scope, not silent gaps.

---

## Self-Review Notes

- **Spec coverage:** Outputs (mode/scale/transform/position) — Tasks 3, 8. Input (touchpad/mouse/trackpoint/gestures) — Task 4 covers all 18 fields in the Python layer; Task 8's UI covers the highest-value subset and explicitly defers the rest as a fast-follow, not a silent drop. Decorations (gaps/focus-ring/border/shadow/animations/blur/cursor) — Task 5 covers all 23 fields in the Python layer; Task 10's UI covers 8 of them and defers center-focused-column/always-center-single-column/shadow softness-spread-offset-color/per-animation durations as fast-follow UI work using the exact same components. Safety pipeline (validate/backup/atomic-write) — Task 2. Live-reload confirmation — Task 11 Step 1. Window rules — explicitly out of scope per the spec's Non-goals.
- **Placeholder scan:** no TBD/TODO left; Task 10's "confirm the exact `id:`" instruction is a read-the-file-first directive (this file wasn't fully read during planning), not a vague implementation gap — everything else is concrete code.
- **Type consistency:** `WriteResult(ok, error, backup_path)` matches its Task 2 definition everywhere it's referenced (only within Task 2/6). CLI field-key strings (`"touchpad-tap"`, `"gaps"`, etc.) match exactly between Task 6's `_FIELDS` dict and Tasks 8/10's QML `cliField` values.
