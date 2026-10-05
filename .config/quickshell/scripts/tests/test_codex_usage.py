import importlib.util
from datetime import datetime, timezone
from pathlib import Path

import pytest

SPEC = importlib.util.spec_from_file_location(
    "codex_usage", Path(__file__).parents[1] / "codex-usage.py"
)
usage = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(usage)


def test_windows_map_by_duration_and_preserve_zero():
    result = usage.parse_windows({"rate_limit": {
        "primary_window": {"limit_window_seconds": 604800, "used_percent": 0, "reset_at": 2000000000},
        "secondary_window": {"limit_window_seconds": 18000, "used_percent": 100, "reset_at": 1900000000},
    }})
    assert result == ({"used_percent": 100, "reset_at": 1900000000},
                      {"used_percent": 0, "reset_at": 2000000000})


def test_unknown_windows_are_not_reported_as_unused():
    assert usage.parse_windows({"rate_limit": {
        "primary_window": {"limit_window_seconds": 3600, "used_percent": 10, "reset_at": 1900000000}
    }}) == (None, None)
    assert usage.parse_windows({"rate_limit": None}) == (None, None)


@pytest.mark.parametrize("percent", [None, True, -1, 101, "6", float("nan")])
def test_invalid_utilization_is_unavailable(percent):
    assert usage.parse_windows({"rate_limit": {"primary_window": {
        "limit_window_seconds": 18000, "used_percent": percent, "reset_at": 1900000000
    }}}) == (None, None)


def test_inventory_counts_only_usable_unexpired_full_resets():
    now = datetime(2026, 10, 5, tzinfo=timezone.utc)
    base = {"reset_type": "codex_rate_limits", "is_supported_by_plan": True,
            "status": "available", "expires_at": "2026-10-22T18:41:07Z"}
    credits = [base, dict(base, expires_at="2026-10-10T00:00:00Z"),
               dict(base, status="redeemed"), dict(base, is_supported_by_plan=False),
               dict(base, expires_at="2026-10-05T00:00:00Z"),
               dict(base, reset_type="other")]
    assert usage.parse_resets({"credits": credits}, now) == {
        "available": 2, "next_expiry": "2026-10-10T00:00:00Z"
    }


def test_empty_inventory_is_zero_but_missing_or_malformed_is_unknown():
    now = datetime(2026, 10, 5, tzinfo=timezone.utc)
    assert usage.parse_resets({"credits": []}, now) == {"available": 0, "next_expiry": None}
    for payload in [{}, {"credits": None}, {"credits": [None]}, {"credits": [{
        "reset_type": "codex_rate_limits", "is_supported_by_plan": True,
        "status": "available", "expires_at": "not-a-date"
    }]}]:
        with pytest.raises(ValueError):
            usage.parse_resets(payload, now)
