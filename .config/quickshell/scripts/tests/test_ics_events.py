import datetime as dt
import importlib.util
import json
import os
import subprocess
import sys
from pathlib import Path

SCRIPT = Path(__file__).parents[1] / "ics_events.py"
spec = importlib.util.spec_from_file_location("ics_events", SCRIPT)
ics = importlib.util.module_from_spec(spec)
spec.loader.exec_module(ics)

D = dt.date


def cal(*events):
    return "BEGIN:VCALENDAR\r\nVERSION:2.0\r\n" + "".join(
        "BEGIN:VEVENT\r\n" + "\r\n".join(e.strip().splitlines()) + "\r\nEND:VEVENT\r\n" for e in events
    ) + "END:VCALENDAR\r\n"


def titles(events):
    return [(e["date"], e["title"]) for e in events]


def test_utc_event_converts_to_local_and_orders_all_day_first():
    local = dt.datetime(2026, 10, 25, 9, 0, tzinfo=ics.LOCAL).astimezone(dt.timezone.utc)
    text = cal(
        f"UID:a\nSUMMARY:Standup\nDTSTART:{local:%Y%m%dT%H%M%S}Z\nDTEND:{(local + dt.timedelta(minutes=30)):%Y%m%dT%H%M%S}Z",
        "UID:b\nSUMMARY:Holiday\nDTSTART;VALUE=DATE:20261025\nDTEND;VALUE=DATE:20261026",
    )
    ev = ics.parse_events(text, D(2026, 10, 25), D(2026, 10, 26))
    assert [(e["title"], e["allDay"], e["start"], e["end"]) for e in ev] == [
        ("Holiday", True, "", ""),
        ("Standup", False, "09:00", "09:30"),
    ]


def test_range_is_start_inclusive_end_exclusive():
    text = cal("UID:a\nSUMMARY:X\nDTSTART;VALUE=DATE:20261101\nDTEND;VALUE=DATE:20261102")
    assert ics.parse_events(text, D(2026, 10, 1), D(2026, 11, 1)) == []
    assert len(ics.parse_events(text, D(2026, 11, 1), D(2026, 11, 2))) == 1


def test_multi_day_all_day_spans_each_day_and_clips_to_range():
    text = cal("UID:a\nSUMMARY:Trip\nDTSTART;VALUE=DATE:20261030\nDTEND;VALUE=DATE:20261102")
    ev = ics.parse_events(text, D(2026, 10, 31), D(2026, 11, 30))
    assert [e["date"] for e in ev] == ["2026-10-31", "2026-11-01"]


def test_timed_event_ending_at_midnight_does_not_spill_to_next_day():
    text = cal("UID:a\nSUMMARY:Late\nDTSTART:20261025T220000\nDTEND:20261026T000000")
    ev = ics.parse_events(text, D(2026, 10, 25), D(2026, 10, 28))
    assert [e["date"] for e in ev] == ["2026-10-25"]


def test_weekly_rrule_byday_count_and_exdate():
    text = cal(
        "UID:w\nSUMMARY:Gym\nDTSTART:20261005T180000\nDTEND:20261005T190000\n"
        "RRULE:FREQ=WEEKLY;BYDAY=MO,TH;COUNT=6\nEXDATE:20261008T180000"
    )
    ev = ics.parse_events(text, D(2026, 10, 1), D(2026, 12, 1))
    # Oct 5 M, (Oct 8 H excluded), Oct 12 M, Oct 15 H, Oct 19 M, Oct 22 H: 6 produced, 1 excluded
    assert [e["date"] for e in ev] == ["2026-10-05", "2026-10-12", "2026-10-15", "2026-10-19", "2026-10-22"]


def test_daily_until_interval():
    text = cal("UID:d\nSUMMARY:Pill\nDTSTART;VALUE=DATE:20261001\nRRULE:FREQ=DAILY;INTERVAL=2;UNTIL=20261007")
    ev = ics.parse_events(text, D(2026, 10, 1), D(2026, 11, 1))
    assert [e["date"][-2:] for e in ev] == ["01", "03", "05", "07"]


def test_monthly_skips_months_without_the_day():
    text = cal("UID:m\nSUMMARY:Bill\nDTSTART;VALUE=DATE:20261031\nRRULE:FREQ=MONTHLY")
    ev = ics.parse_events(text, D(2026, 10, 1), D(2027, 1, 1))
    assert [e["date"] for e in ev] == ["2026-10-31", "2026-12-31"]


def test_monthly_nth_weekday():
    text = cal("UID:m\nSUMMARY:Sync\nDTSTART;VALUE=DATE:20261002\nRRULE:FREQ=MONTHLY;BYDAY=1FR")
    ev = ics.parse_events(text, D(2026, 10, 1), D(2027, 1, 1))
    assert [e["date"] for e in ev] == ["2026-10-02", "2026-11-06", "2026-12-04"]


def test_yearly_birthday():
    text = cal("UID:y\nSUMMARY:Bday\nDTSTART;VALUE=DATE:20000225\nRRULE:FREQ=YEARLY")
    ev = ics.parse_events(text, D(2026, 10, 1), D(2027, 3, 1))
    assert [e["date"] for e in ev] == ["2027-02-25"]


def test_override_replaces_instance_and_cancelled_is_dropped():
    text = cal(
        "UID:r\nSUMMARY:Class\nDTSTART:20261005T100000Z\nDTEND:20261005T110000Z\nRRULE:FREQ=DAILY;COUNT=3",
        "UID:r\nSUMMARY:Class moved\nRECURRENCE-ID:20261006T100000Z\nDTSTART:20261006T150000Z\nDTEND:20261006T160000Z",
        "UID:c\nSUMMARY:Gone\nSTATUS:CANCELLED\nDTSTART;VALUE=DATE:20261006",
    )
    ev = ics.parse_events(text, D(2026, 10, 4), D(2026, 10, 9))
    assert sorted(e["title"] for e in ev) == ["Class", "Class", "Class moved"]
    assert "Gone" not in [e["title"] for e in ev]


def test_tzid_recurring_event_keeps_wall_clock_across_dst():
    text = cal(
        "UID:t\nSUMMARY:Call\nDTSTART;TZID=America/New_York:20261030T090000\n"
        "DTEND;TZID=America/New_York:20261030T100000\nRRULE:FREQ=WEEKLY;COUNT=2"   # DST ends Nov 1
    )
    ev = ics.parse_events(text, D(2026, 10, 29), D(2026, 11, 10))
    ny = lambda d, h: dt.datetime(*d, h, tzinfo=ics.ZoneInfo("America/New_York")).astimezone(ics.LOCAL)
    assert [e["start"] for e in ev] == [
        ny((2026, 10, 30), 9).strftime("%H:%M"),
        ny((2026, 11, 6), 9).strftime("%H:%M"),
    ]


def test_folded_lines_and_escapes():
    text = "BEGIN:VEVENT\r\nSUMMARY:Lunch\\, with\r\n  Sam\r\nDTSTART;VALUE=DATE:20261025\r\nEND:VEVENT\r\n"
    ev = ics.parse_events(text, D(2026, 10, 25), D(2026, 10, 26))
    assert ev[0]["title"] == "Lunch, with Sam"


def run_cli(tmp_path, url_text, *args):
    url_file = tmp_path / "url"
    if url_text is not None:
        url_file.write_text(url_text)
    env = dict(os.environ, QS_CALENDAR_URL_FILE=str(url_file))
    out = subprocess.run([sys.executable, str(SCRIPT), *args], env=env, capture_output=True, text=True)
    assert out.returncode == 0
    return json.loads(out.stdout)


def test_cli_unconfigured_when_no_url(tmp_path):
    assert run_cli(tmp_path, None, "2026-10-01", "2026-11-01")["status"] == "unconfigured"
    assert run_cli(tmp_path, "  \n", "2026-10-01", "2026-11-01")["status"] == "unconfigured"


def test_cli_reads_file_url_and_reports_fetch_errors(tmp_path):
    ics_file = tmp_path / "c.ics"
    ics_file.write_text(cal("UID:a\nSUMMARY:Hi\nDTSTART;VALUE=DATE:20261025"))
    ok = run_cli(tmp_path, ics_file.as_uri(), "2026-10-25", "2026-10-26")
    assert ok["status"] == "ok" and titles(ok["events"]) == [("2026-10-25", "Hi")]
    bad = run_cli(tmp_path, (tmp_path / "missing.ics").as_uri(), "2026-10-25", "2026-10-26")
    assert bad["status"] == "error" and "failed" in bad["message"]


def test_cli_merges_several_links_and_keeps_good_ones_on_partial_failure(tmp_path):
    a, b = tmp_path / "a.ics", tmp_path / "b.ics"
    a.write_text(cal("UID:a\nSUMMARY:Home thing\nDTSTART;VALUE=DATE:20261025"))
    b.write_text(cal("UID:b\nSUMMARY:Work thing\nDTSTART:20261025T090000"))
    links = "# comment\n" + a.as_uri() + "\n\n" + b.as_uri() + "\n"
    ok = run_cli(tmp_path, links, "2026-10-25", "2026-10-26")
    assert ok["status"] == "ok" and [e["title"] for e in ok["events"]] == ["Home thing", "Work thing"]
    part = run_cli(tmp_path, links + (tmp_path / "gone.ics").as_uri() + "\n", "2026-10-25", "2026-10-26")
    assert part["status"] == "error" and part["message"].startswith("1 of 3") and len(part["events"]) == 2


def test_calendar_color_passes_through_and_lightens_dark_blue():
    ev = "BEGIN:VEVENT\r\nUID:a\r\nSUMMARY:X\r\nDTSTART;VALUE=DATE:20261025\r\nEND:VEVENT\r\n"
    def color(c):
        text = "BEGIN:VCALENDAR\r\n" + (f"X-APPLE-CALENDAR-COLOR:{c}\r\n" if c else "") + ev + "END:VCALENDAR\r\n"
        return ics.parse_events(text, D(2026, 10, 25), D(2026, 10, 26))[0]["color"]
    assert color("#34AADCFF") == "#34aadc"
    assert color("#0000ff") == "#7f7fff"
    assert color("#zzzzzz") == ""
    assert color(None) == ""


def test_cli_bad_args(tmp_path):
    assert run_cli(tmp_path, None, "nope")["status"] == "error"
