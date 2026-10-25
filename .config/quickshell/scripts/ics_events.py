#!/usr/bin/env python3
"""Events from a public iCloud (Apple Calendar) ICS link, as JSON for the sidebar.

usage: ics_events.py START END      dates YYYY-MM-DD, START inclusive, END exclusive
The link (webcal:// or https://) lives in ~/.local/state/quickshell/calendar-url,
outside the dotfiles repo because anyone holding it can read the calendar.
Always prints one JSON object and exits 0: {status, message, updated_at, events}.
status is "ok", "unconfigured" or "error".
"""
import calendar
import datetime as dt
import json
import os
import sys
import urllib.request
from zoneinfo import ZoneInfo

REQUEST_TIMEOUT = 10
MAX_STEPS = 20000      # ponytail: caps runaway RRULEs; raise if a daily event older than ~50y matters
URL_FILE = os.environ.get("QS_CALENDAR_URL_FILE") or os.path.expanduser("~/.local/state/quickshell/calendar-url")
WEEKDAYS = ["MO", "TU", "WE", "TH", "FR", "SA", "SU"]
LOCAL = dt.datetime.now().astimezone().tzinfo


def unfold(text):
    out = []
    for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n"):
        if line[:1] in (" ", "\t") and out:
            out[-1] += line[1:]
        elif line:
            out.append(line)
    return out


def unescape(value):
    return value.replace("\\n", "\n").replace("\\N", "\n").replace("\\,", ",").replace("\\;", ";").replace("\\\\", "\\")


def parse_prop(line):
    head, _, value = line.partition(":")
    name, *rawparams = head.split(";")
    params = dict(p.split("=", 1) for p in rawparams if "=" in p)
    return name.upper(), params, value


def components(text):
    """Yield one {NAME: [(params, value), ...]} per VEVENT."""
    cur = None
    for line in unfold(text):
        if line == "BEGIN:VEVENT":
            cur = {}
        elif line == "END:VEVENT":
            if cur is not None:
                yield cur
            cur = None
        elif cur is not None and ":" in line:
            name, params, value = parse_prop(line)
            cur.setdefault(name, []).append((params, value))


def to_dt(params, value):
    """Date (all-day) or tz-aware datetime. Floating times count as local."""
    if params.get("VALUE") == "DATE" or (len(value) == 8 and value.isdigit()):
        return dt.datetime.strptime(value[:8], "%Y%m%d").date()
    utc = value.endswith("Z")
    naive = dt.datetime.strptime(value.rstrip("Z"), "%Y%m%dT%H%M%S")
    if utc:
        return naive.replace(tzinfo=dt.timezone.utc)
    try:
        tz = ZoneInfo(params["TZID"]) if "TZID" in params else LOCAL
    except Exception:
        tz = LOCAL
    return naive.replace(tzinfo=tz)


def first(comp, name):
    return comp[name][0] if name in comp else None


def norm(v):
    """Comparable key: date as-is, datetime as UTC."""
    return v if type(v) is dt.date else v.astimezone(dt.timezone.utc)


def parse_rrule(value):
    rule = dict(p.split("=", 1) for p in value.split(";") if "=" in p)
    byday = []
    for item in rule.get("BYDAY", "").split(","):
        if item:
            byday.append((int(item[:-2]) if item[:-2] else 0, WEEKDAYS.index(item[-2:])))
    return {
        "freq": rule.get("FREQ", ""),
        "interval": max(1, int(rule.get("INTERVAL", 1))),
        "count": int(rule["COUNT"]) if "COUNT" in rule else None,
        "until": to_dt({}, rule["UNTIL"]) if "UNTIL" in rule else None,
        "byday": byday,
        "bymonthday": [int(d) for d in rule.get("BYMONTHDAY", "").split(",") if d],
    }


def nth_weekday(year, month, n, wd):
    days = [d for d in range(1, calendar.monthrange(year, month)[1] + 1)
            if dt.date(year, month, d).weekday() == wd]
    try:
        return days[n - 1 if n > 0 else n]
    except IndexError:
        return None


def occurrences(start, rule):
    """Yield start, then each later recurrence start, in order."""
    if not rule["freq"]:
        yield start
        return
    freq, step = rule["freq"], rule["interval"]
    base = start if type(start) is dt.datetime else dt.datetime.combine(start, dt.time())
    produced = 0

    def emit(candidate):
        return candidate.date() if type(start) is dt.date else candidate

    for k in range(MAX_STEPS):
        cands = []
        if freq == "DAILY":
            cands = [base + dt.timedelta(days=k * step)]
        elif freq == "WEEKLY":
            monday = base - dt.timedelta(days=base.weekday()) + dt.timedelta(weeks=k * step)
            wds = sorted({wd for _, wd in rule["byday"]}) or [base.weekday()]
            cands = [monday + dt.timedelta(days=wd) for wd in wds]
        elif freq in ("MONTHLY", "YEARLY"):
            months = k * step * (12 if freq == "YEARLY" else 1)
            y, m = base.year + (base.month - 1 + months) // 12, (base.month - 1 + months) % 12 + 1
            if rule["byday"] and freq == "MONTHLY":
                days = [nth_weekday(y, m, n or 1, wd) for n, wd in rule["byday"]]
            else:
                days = rule["bymonthday"] or [base.day]
            for d in days:
                try:
                    cands.append(base.replace(year=y, month=m, day=d))
                except (ValueError, TypeError):
                    pass   # month without that day: skipped, as RFC 5545 says
        else:
            yield start    # ponytail: HOURLY/MINUTELY unsupported, show the first instance only
            return
        for c in sorted(cands):
            if c < base:
                continue
            out = emit(c)
            if rule["until"] is not None and norm(out) > norm(rule["until"]):
                return
            yield out
            produced += 1
            if rule["count"] is not None and produced >= rule["count"]:
                return


def parse_events(text, range_start, range_end):
    """Events with any day in [range_start, range_end), local time, sorted."""
    comps = list(components(text))
    overridden = set()
    for c in comps:
        rid = first(c, "RECURRENCE-ID")
        if rid:
            overridden.add((first(c, "UID")[1], norm(to_dt(*rid))))
    events = []
    for c in comps:
        if "DTSTART" not in c or (first(c, "STATUS") or ({}, ""))[1].upper() == "CANCELLED":
            continue
        start = to_dt(*c["DTSTART"][0])
        all_day = type(start) is dt.date
        if "DTEND" in c:
            length = to_dt(*c["DTEND"][0]) - start
        else:
            length = dt.timedelta(days=1) if all_day else dt.timedelta()
        title = unescape((first(c, "SUMMARY") or ({}, "(no title)"))[1])
        uid = (first(c, "UID") or ({}, ""))[1]
        is_override = "RECURRENCE-ID" in c
        rule = parse_rrule(first(c, "RRULE")[1]) if "RRULE" in c and not is_override else {"freq": "", "count": None, "until": None}
        exdates = set()
        for params, raw in c.get("EXDATE", []):
            exdates |= {norm(to_dt(params, v.strip())) for v in raw.split(",") if v.strip()}
        for s in occurrences(start, rule):
            if all_day:
                ls, le = s, s + length
                first_day, last_day = ls, max(ls, le - dt.timedelta(days=1))
            else:
                ls, le = s.astimezone(LOCAL), (s + length).astimezone(LOCAL)
                first_day = ls.date()
                last_day = (le - dt.timedelta(microseconds=1)).date() if le > ls else first_day
            if first_day >= range_end:
                break
            if norm(s) in exdates or (not is_override and (uid, norm(s)) in overridden):
                continue
            day = max(first_day, range_start)
            while day <= last_day and day < range_end:
                events.append({
                    "date": day.isoformat(),
                    "start": "" if all_day else ls.strftime("%H:%M"),
                    "end": "" if all_day or length == dt.timedelta() else le.strftime("%H:%M"),
                    "title": title,
                    "allDay": all_day,
                })
                day += dt.timedelta(days=1)
    events.sort(key=lambda ev: (ev["date"], not ev["allDay"], ev["start"], ev["title"]))
    return events


def fetch(url):
    if url.lower().startswith("webcal"):
        url = "https" + url[len("webcal"):]
    req = urllib.request.Request(url, headers={"User-Agent": "Quickshell Calendar"})
    with urllib.request.urlopen(req, timeout=REQUEST_TIMEOUT) as response:
        return response.read().decode("utf-8", "replace")


def result(status, message="", events=None):
    return {"status": status, "message": message, "updated_at": dt.datetime.now().strftime("%H:%M"), "events": events or []}


def run(start, end):
    try:
        url = open(URL_FILE, encoding="utf-8").read().strip()
    except OSError:
        return result("unconfigured", "Paste your iCloud public calendar link into " + URL_FILE)
    if not url:
        return result("unconfigured", "Paste your iCloud public calendar link into " + URL_FILE)
    try:
        return result("ok", "", parse_events(fetch(url), start, end))
    except Exception as error:
        return result("error", "Calendar fetch failed: %s" % error)


if __name__ == "__main__":
    try:
        a, b = (dt.date.fromisoformat(arg) for arg in sys.argv[1:3])
    except (ValueError, IndexError):
        print(json.dumps(result("error", "usage: ics_events.py START END")))
        sys.exit(0)
    print(json.dumps(run(a, b)))
