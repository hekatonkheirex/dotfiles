from scripts.niri_config import kdl_edit as k

SAMPLE = '''\
touchpad {
    tap
    natural-scroll
    scroll-method "two-finger"
}

mouse {
}

output "eDP-1" {
  mode "1920x1080@60.020"
  scale 1
  position x=1280 y=0
}
'''


def _span(header):
    return k.find_block(SAMPLE, header)


def test_find_block_locates_body():
    start, end = _span(r'touchpad\s*\{')
    assert SAMPLE[start:end].strip().startswith("tap")


def test_find_block_missing_raises():
    import pytest
    with pytest.raises(ValueError):
        k.find_block(SAMPLE, r'nonexistent\s*\{')


def test_find_nested_block():
    outer = k.find_block(SAMPLE, r'output\s+"eDP-1"\s*\{')
    # position is a scalar line, not a block, so nest into touchpad->none;
    # instead prove nesting against a synthetic multi-level sample.
    nested_sample = "outer {\n  inner {\n    x 1\n  }\n}\n"
    outer2 = k.find_block(nested_sample, r'outer\s*\{')
    inner = k.find_nested_block(nested_sample, outer2, r'inner\s*\{')
    assert nested_sample[inner[0]:inner[1]].strip() == "x 1"


def test_read_write_number_replace():
    span = _span(r'output\s+"eDP-1"\s*\{')
    assert k.read_number(SAMPLE, span, "scale") == 1.0
    new_text = k.write_number(SAMPLE, span, "scale", 1.5)
    span2 = k.find_block(new_text, r'output\s+"eDP-1"\s*\{')
    assert k.read_number(new_text, span2, "scale") == 1.5
    # untouched fields survive
    assert k.read_string(new_text, span2, "mode") == "1920x1080@60.020"


def test_write_number_inserts_when_absent():
    span = _span(r'mouse\s*\{')
    assert k.read_number(SAMPLE, span, "accel-speed") is None
    new_text = k.write_number(SAMPLE, span, "accel-speed", 0.2)
    span2 = k.find_block(new_text, r'mouse\s*\{')
    assert k.read_number(new_text, span2, "accel-speed") == 0.2


def test_read_write_string_replace():
    span = _span(r'output\s+"eDP-1"\s*\{')
    assert k.read_string(SAMPLE, span, "mode") == "1920x1080@60.020"
    new_text = k.write_string(SAMPLE, span, "mode", "2560x1440@60.000")
    span2 = k.find_block(new_text, r'output\s+"eDP-1"\s*\{')
    assert k.read_string(new_text, span2, "mode") == "2560x1440@60.000"


def test_flag_read_write_roundtrip():
    span = _span(r'touchpad\s*\{')
    assert k.read_flag(SAMPLE, span, "tap") is True
    assert k.read_flag(SAMPLE, span, "disabled-on-external-mouse") is False
    disabled = k.write_flag(SAMPLE, span, "tap", False)
    span2 = k.find_block(disabled, r'touchpad\s*\{')
    assert k.read_flag(disabled, span2, "tap") is False
    enabled = k.write_flag(disabled, span2, "tap", True)
    span3 = k.find_block(enabled, r'touchpad\s*\{')
    assert k.read_flag(enabled, span3, "tap") is True


def test_flag_write_noop_when_already_matches():
    span = _span(r'touchpad\s*\{')
    same = k.write_flag(SAMPLE, span, "tap", True)
    assert same == SAMPLE


def test_bool_kv_roundtrip():
    text = "layout {\n  always-center-single-column true\n}\n"
    span = k.find_block(text, r'layout\s*\{')
    assert k.read_bool_kv(text, span, "always-center-single-column") is True
    new_text = k.write_bool_kv(text, span, "always-center-single-column", False)
    span2 = k.find_block(new_text, r'layout\s*\{')
    assert k.read_bool_kv(new_text, span2, "always-center-single-column") is False


def test_on_off_roundtrip():
    text = "focus-ring {\n  on\n  width 2\n}\n"
    span = k.find_block(text, r'focus-ring\s*\{')
    assert k.read_on_off(text, span) is True
    new_text = k.write_on_off(text, span, False)
    span2 = k.find_block(new_text, r'focus-ring\s*\{')
    assert k.read_on_off(new_text, span2) is False
    # width survives untouched
    assert k.read_number(new_text, span2, "width") == 2.0


def test_on_off_inserts_when_absent():
    text = "blur {\n  passes 3\n}\n"
    span = k.find_block(text, r'blur\s*\{')
    assert k.read_on_off(text, span) is None
    new_text = k.write_on_off(text, span, False)
    span2 = k.find_block(new_text, r'blur\s*\{')
    assert k.read_on_off(new_text, span2) is False
    assert k.read_number(new_text, span2, "passes") == 3.0


def test_named_args_roundtrip():
    span = _span(r'output\s+"eDP-1"\s*\{')
    assert k.read_named_args(SAMPLE, span, "position", ["x", "y"]) == (1280.0, 0.0)
    new_text = k.write_named_args(SAMPLE, span, "position", ["x", "y"], [0.0, 0.0])
    span2 = k.find_block(new_text, r'output\s+"eDP-1"\s*\{')
    assert k.read_named_args(new_text, span2, "position", ["x", "y"]) == (0.0, 0.0)
