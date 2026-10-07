import importlib.util
from datetime import datetime, timezone
from pathlib import Path

import pytest

SPEC = importlib.util.spec_from_file_location(
    "claude_usage", Path(__file__).parents[1] / "claude-usage.py"
)
usage = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(usage)


def test_quota_windows_preserve_zero_and_parse_timezone():
    result = usage.parse_windows({
        "five_hour": {"utilization": 0, "resets_at": "2026-10-05T16:40:00+00:00"},
        "seven_day": {"utilization": 11.5, "resets_at": "2026-10-12T04:00:00+03:00"},
    })
    assert result == (
        {"used_percent": 0, "reset_at": int(datetime(2026, 10, 5, 16, 40, tzinfo=timezone.utc).timestamp())},
        {"used_percent": 11.5, "reset_at": int(datetime(2026, 10, 12, 1, tzinfo=timezone.utc).timestamp())},
    )


@pytest.mark.parametrize("window", [None, {}, {"utilization": None},
    {"utilization": True, "resets_at": "2026-10-05T16:40:00Z"},
    {"utilization": -1, "resets_at": "2026-10-05T16:40:00Z"},
    {"utilization": 101, "resets_at": "2026-10-05T16:40:00Z"},
    {"utilization": 10, "resets_at": "invalid"},
    {"utilization": 10, "resets_at": "2026-10-05T16:40:00"}])
def test_missing_or_invalid_quota_is_unknown(window):
    assert usage.parse_windows({"five_hour": window, "seven_day": None}) == (None, None)


def test_inventory_excludes_paused_future_expired_and_used_grants():
    now = datetime(2026, 10, 5, tzinfo=timezone.utc)
    base = {"resets_left": 1, "resets_total": 1, "paused": False,
            "starts_at": "2026-09-22T16:00:00Z", "ends_at": "2026-10-22T16:00:00Z"}
    grants = [base, dict(base, resets_left=2, resets_total=2, ends_at="2026-10-10T00:00:00Z"),
              dict(base, paused=True), dict(base, starts_at="2026-10-06T00:00:00Z"),
              dict(base, ends_at="2026-10-05T00:00:00Z"), dict(base, resets_left=0)]
    assert usage.parse_resets({"eligible": True, "grants": grants}, now) == {
        "available": 3, "next_expiry": "2026-10-10T00:00:00Z"
    }


def test_reset_unknown_and_ineligible_are_not_zero():
    now = datetime(2026, 10, 5, tzinfo=timezone.utc)
    assert usage.parse_resets({"eligible": True, "grants": []}, now) == {"available": 0, "next_expiry": None}
    for block in [None, {}, {"eligible": False, "grants": []},
                  {"eligible": True, "grants": [None]},
                  {"eligible": True, "grants": [{"resets_left": True}]}]:
        with pytest.raises(ValueError):
            usage.parse_resets(block, now)


@pytest.mark.parametrize("header,expected", [
    ("400", 400),
    ("Mon, 05 Oct 2026 00:07:00 GMT", 420),
    ("3600", 600),
    ("Mon, 05 Oct 2026 01:00:00 GMT", 600),
    ("0", 300),
    ("Mon, 05 Oct 2026 00:00:00 GMT", 300),
    ("invalid", 300),
    (None, 300),
])
def test_rate_limit_cooldown_honors_server_deadline_without_fast_retry(header, expected):
    now = datetime(2026, 10, 5, tzinfo=timezone.utc)
    assert usage.rate_limit_delay(header, now) == expected
