#!/usr/bin/env python3
"""Read Codex subscription quota; never renew credentials or redeem resets."""
import json
import math
import os
from datetime import datetime, timezone
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, Request, build_opener

BASE_URL = "https://chatgpt.com/backend-api/wham/"


class NoRedirect(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        # Do not forward account credentials to redirects or login pages.
        return None


def parse_windows(payload):
    if not isinstance(payload, dict):
        raise ValueError("Invalid usage response")
    windows = {18000: None, 604800: None}
    limits = payload.get("rate_limit") or {}
    if not isinstance(limits, dict):
        raise ValueError("Invalid rate limits")
    for key in ("primary_window", "secondary_window"):
        window = limits.get(key)
        if not isinstance(window, dict):
            continue
        duration = window.get("limit_window_seconds")
        if type(duration) is not int or duration not in windows:
            continue
        percent, reset = window.get("used_percent"), window.get("reset_at")
        if (type(percent) not in (int, float) or not math.isfinite(percent)
                or not 0 <= percent <= 100 or type(reset) is not int or reset <= 0):
            continue
        windows[duration] = {"used_percent": percent, "reset_at": reset}
    return windows[18000], windows[604800]


def parse_resets(payload, now):
    if not isinstance(payload, dict) or not isinstance(payload.get("credits"), list):
        raise ValueError("Invalid reset inventory")
    expiries = []
    for credit in payload["credits"]:
        if not isinstance(credit, dict):
            raise ValueError("Invalid reset credit")
        if credit.get("reset_type") != "codex_rate_limits":
            continue
        if (type(credit.get("is_supported_by_plan")) is not bool
                or not isinstance(credit.get("status"), str)):
            raise ValueError("Incomplete reset credit")
        if not credit["is_supported_by_plan"] or credit["status"] != "available":
            continue
        expiry = datetime.fromisoformat(credit["expires_at"].replace("Z", "+00:00"))
        if expiry.tzinfo is None:
            raise ValueError("Reset expiry has no timezone")
        if expiry > now:
            expiries.append(expiry)
    return {"available": len(expiries), "next_expiry": (
        min(expiries).astimezone(timezone.utc).isoformat().replace("+00:00", "Z")
        if expiries else None)}


def fetch(endpoint, headers):
    request = Request(BASE_URL + endpoint, headers=headers)
    with build_opener(NoRedirect).open(request, timeout=12) as response:
        return json.load(response)


def error_message(error):
    if isinstance(error, HTTPError):
        if error.code == 401:
            return "Codex sign-in expired. Run codex login to renew it."
        if error.code == 403:
            return "OpenAI denied access to Codex usage for this account."
        if error.code == 429:
            return "OpenAI rate-limited usage checks. Try again later."
        return "OpenAI usage request failed (HTTP " + str(error.code) + ")."
    if isinstance(error, (URLError, TimeoutError, OSError)):
        return "Cannot reach OpenAI. Check your connection and refresh."
    return "OpenAI returned an unreadable usage response."


def read_usage():
    result = {"status": "error", "message": "", "updated_at": "",
              "five_hour": None, "weekly": None, "resets": None, "resets_message": ""}
    home = Path(os.environ.get("CODEX_HOME") or str(Path.home() / ".codex")).expanduser()
    try:
        auth = json.loads((home / "auth.json").read_text())
        tokens = auth.get("tokens") or {}
        token = tokens.get("access_token")
        if not isinstance(token, str) or not token:
            result["message"] = "Sign in with your ChatGPT account using codex login. API keys do not report subscription quota."
            return result
        headers = {"Authorization": "Bearer " + token, "User-Agent": "quickshell-codex-usage"}
        account = tokens.get("account_id")
        if isinstance(account, str) and account:
            headers["ChatGPT-Account-Id"] = account
    except (OSError, ValueError, AttributeError):
        result["message"] = "Codex sign-in is unavailable. Run codex login for this Codex home."
        return result
    try:
        result["five_hour"], result["weekly"] = parse_windows(fetch("usage", headers))
    except (HTTPError, URLError, OSError, ValueError, TypeError) as error:
        result["message"] = error_message(error)
        return result
    now = datetime.now(timezone.utc)
    result.update(status="ok", updated_at=now.isoformat().replace("+00:00", "Z"))
    if result["five_hour"] is None and result["weekly"] is None:
        result["message"] = "OpenAI did not report five-hour or weekly limits for this account."
    try:
        result["resets"] = parse_resets(fetch("rate-limit-reset-credits", headers), now)
    except (HTTPError, URLError, OSError, ValueError, TypeError, KeyError, AttributeError):
        result["resets_message"] = "Available resets could not be read from OpenAI."
    return result


if __name__ == "__main__":
    print(json.dumps(read_usage(), allow_nan=False))
