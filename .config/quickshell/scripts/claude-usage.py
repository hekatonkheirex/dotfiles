#!/usr/bin/env python3
"""Read Claude subscription usage and saved resets without changing sign-in."""
import json
import math
import os
import re
import shutil
import subprocess
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener

USAGE_URL = "https://api.anthropic.com/api/oauth/usage"


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


def timestamp(value):
    if not isinstance(value, str):
        raise ValueError("Missing timestamp")
    parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if parsed.tzinfo is None:
        raise ValueError("Timestamp has no timezone")
    return parsed.astimezone(timezone.utc)


def parse_windows(payload):
    if not isinstance(payload, dict):
        raise ValueError("Invalid usage response")
    windows = []
    for key in ("five_hour", "seven_day"):
        window = payload.get(key)
        reading = None
        if isinstance(window, dict):
            percent = window.get("utilization")
            if type(percent) in (int, float) and math.isfinite(percent) and 0 <= percent <= 100:
                try:
                    reset = int(timestamp(window.get("resets_at")).timestamp())
                    if reset > 0:
                        reading = {"used_percent": percent, "reset_at": reset}
                except ValueError:
                    pass
        windows.append(reading)
    return tuple(windows)


def parse_resets(block, now):
    if (not isinstance(block, dict) or block.get("eligible") is not True
            or not isinstance(block.get("grants"), list)):
        raise ValueError("Reset inventory unavailable")
    count, expiries = 0, []
    for grant in block["grants"]:
        if not isinstance(grant, dict):
            raise ValueError("Invalid reset grant")
        left, total, paused = grant.get("resets_left"), grant.get("resets_total"), grant.get("paused")
        if (type(left) is not int or type(total) is not int or type(paused) is not bool
                or not 0 <= left <= total):
            raise ValueError("Invalid reset grant counts")
        start, end = timestamp(grant.get("starts_at")), timestamp(grant.get("ends_at"))
        if start >= end:
            raise ValueError("Invalid reset grant lifetime")
        # usable_now can be false until a limit is reached; saved credits still count.
        if not paused and start <= now < end and left > 0:
            count += left
            expiries.append(end)
    return {"available": count, "next_expiry": (
        min(expiries).isoformat().replace("+00:00", "Z") if expiries else None)}


def cli_version():
    executable = shutil.which("claude")
    if not executable:
        return None
    try:
        result = subprocess.run([executable, "--version"], capture_output=True, text=True, timeout=3, check=True)
        match = re.match(r"(\d+\.\d+\.\d+)\b", result.stdout)
        return match.group(1) if match else None
    except (OSError, subprocess.SubprocessError):
        return None


def fetch(headers, include_resets):
    request = Request(USAGE_URL + ("?cedar_ember=1" if include_resets else ""), headers=headers)
    with build_opener(NoRedirect).open(request, timeout=12) as response:
        return json.load(response)


def rate_limit_delay(header, now):
    # Never retry faster than ordinary polling, even without a usable header.
    try:
        if header is not None and header.strip().isdigit():
            return max(300, int(header))
        deadline = parsedate_to_datetime(header)
        if deadline.tzinfo is not None:
            return max(300, math.ceil((deadline - now).total_seconds()))
    except (TypeError, ValueError, OverflowError, AttributeError):
        pass
    return 300


def error_message(error):
    if isinstance(error, HTTPError):
        if error.code == 401:
            return "Claude sign-in expired. Sign in again in Claude Code."
        if error.code == 403:
            return "Anthropic denied usage access. Use a Claude Code sign-in with user:profile scope."
        if error.code == 429:
            return "Anthropic rate-limited usage checks. Try again later."
        return "Anthropic usage request failed (HTTP " + str(error.code) + ")."
    if isinstance(error, (URLError, OSError)):
        return "Cannot reach Anthropic. Check your connection and refresh."
    return "Anthropic returned an unreadable usage response."


def read_usage():
    result = {"status": "error", "message": "", "updated_at": "",
              "five_hour": None, "weekly": None, "resets": None, "resets_message": ""}
    home = Path(os.environ.get("CLAUDE_CONFIG_DIR") or str(Path.home() / ".claude")).expanduser()
    try:
        auth = json.loads((home / ".credentials.json").read_text())
        oauth = auth.get("claudeAiOauth") or {}
        token = oauth.get("accessToken")
        if not isinstance(token, str) or not token:
            raise ValueError("No OAuth credentials")
    except (OSError, ValueError, AttributeError):
        result["message"] = "Claude sign-in is unavailable. Sign in with your subscription in Claude Code."
        return result
    version = cli_version()
    headers = {"Authorization": "Bearer " + token, "anthropic-beta": "oauth-2025-04-20",
               "User-Agent": "claude-cli/" + version + " (external, cli)" if version else "quickshell-claude-usage"}
    try:
        payload = fetch(headers, include_resets=bool(version))
        result["five_hour"], result["weekly"] = parse_windows(payload)
    except (HTTPError, URLError, OSError, ValueError, TypeError) as error:
        result["message"] = error_message(error)
        if isinstance(error, HTTPError) and error.code == 429:
            result["retry_after_seconds"] = rate_limit_delay(
                error.headers.get("Retry-After") if error.headers else None,
                datetime.now(timezone.utc),
            )
        return result
    now = datetime.now(timezone.utc)
    result.update(status="ok", updated_at=now.isoformat().replace("+00:00", "Z"))
    if result["five_hour"] is None and result["weekly"] is None:
        result["message"] = "Anthropic did not report five-hour or weekly limits for this account."
    block = payload.get("cedar_ember")
    try:
        result["resets"] = parse_resets(block, now)
    except (ValueError, TypeError):
        if not version or isinstance(block, dict) and block.get("ineligible_reason") == "cli_version":
            result["resets_message"] = "Reset credits require a supported installed Claude Code version."
        else:
            result["resets_message"] = "Anthropic did not provide an eligible reset-credit inventory."
    return result


if __name__ == "__main__":
    print(json.dumps(read_usage(), allow_nan=False))
