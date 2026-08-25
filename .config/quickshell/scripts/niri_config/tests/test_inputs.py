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
