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
