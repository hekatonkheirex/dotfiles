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
