#!/usr/bin/env python3
"""Verdict on quickshell memory growth from ~/.cache/qs-rss/progress.log.

Usage: qs-rss-report.py [log] [--min-hours H] [--warmup-min M] [--limit MB_PER_H]

Per quickshell PID: fit a least-squares line to anonymous memory over uptime
(ignoring the first `warmup` minutes, when popups and caches fill) and report
MB/hour, the span and a verdict. Hot reloads (editing files while the shell
runs) inflate memory (~19 MB on the first, ~4 MB after), so a PID that was
edited during the window is not evidence of a leak: sample an idle session.
Exit 1 when a PID with enough data grows faster than the limit.
"""
import re, sys, argparse, collections

LINE = re.compile(r"^(\S+) qs-rss rss=(\d+)MB anon=(\d+)MB shared=\d+MB cgroup=(\d+)MB "
                  r"threads=\d+ fds=(\d+) up=(\d+)s pid=(\d+)")


def parse(lines):
    pids = collections.OrderedDict()
    for line in lines:
        m = LINE.match(line)
        if not m:
            continue
        _, rss, anon, cg, fds, up, pid = m.groups()
        pids.setdefault(pid, []).append((int(up), int(rss), int(anon), int(cg), int(fds)))
    return pids


def slope_per_hour(points):
    """Least squares slope of (uptime_s, value) in value-units per hour."""
    n = len(points)
    if n < 2:
        return 0.0
    mx = sum(p[0] for p in points) / n
    my = sum(p[1] for p in points) / n
    den = sum((p[0] - mx) ** 2 for p in points)
    if den == 0:
        return 0.0
    return sum((p[0] - mx) * (p[1] - my) for p in points) / den * 3600


def report(pids, warmup_min=10, min_hours=1.0, limit=5.0):
    rows, bad = [], False
    for pid, pts in pids.items():
        steady = [(u, a) for (u, _r, a, _c, _f) in pts if u >= warmup_min * 60]
        span_h = (steady[-1][0] - steady[0][0]) / 3600 if len(steady) >= 2 else 0.0
        s = slope_per_hour(steady)
        if span_h < min_hours:
            verdict = "too short"
        elif s > limit:
            verdict = "GROWING"
            bad = True
        else:
            verdict = "flat"
        last = pts[-1]
        rows.append((pid, len(pts), span_h, s, last[2], last[1], last[4], verdict))
    return rows, bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("log", nargs="?", default=None)
    ap.add_argument("--min-hours", type=float, default=1.0)
    ap.add_argument("--warmup-min", type=float, default=10)
    ap.add_argument("--limit", type=float, default=5.0, help="MB/hour of anon growth")
    a = ap.parse_args()
    import os
    path = a.log or os.path.expanduser("~/.cache/qs-rss/progress.log")
    with open(path) as f:
        rows, bad = report(parse(f), a.warmup_min, a.min_hours, a.limit)
    print(f"{'pid':>8} {'n':>4} {'span_h':>7} {'MB/h':>7} {'anon':>6} {'rss':>6} {'fds':>4}  verdict")
    for pid, n, span, s, anon, rss, fds, v in rows:
        print(f"{pid:>8} {n:>4} {span:>7.1f} {s:>7.1f} {anon:>6} {rss:>6} {fds:>4}  {v}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
