"""Read/write fields in decorations.kdl's layout/animations/blur/cursor blocks."""
from . import kdl_edit as k

_LAYOUT = r'layout\s*\{'
_FOCUS_RING = r'focus-ring\s*\{'
_BORDER = r'border\s*\{'
_SHADOW = r'shadow\s*\{'
_ANIMATIONS = r'animations\s*\{'
_BLUR = r'blur\s*\{'
_CURSOR = r'cursor\s*\{'


def _layout_span(text: str) -> tuple[int, int]:
    return k.find_block(text, _LAYOUT)


def _focus_ring_span(text: str) -> tuple[int, int]:
    return k.find_nested_block(text, _layout_span(text), _FOCUS_RING)


def _border_span(text: str) -> tuple[int, int]:
    return k.find_nested_block(text, _layout_span(text), _BORDER)


def _shadow_span(text: str) -> tuple[int, int]:
    return k.find_nested_block(text, _layout_span(text), _SHADOW)


def read_gaps(text: str) -> float | None:
    return k.read_number(text, _layout_span(text), "gaps")


def write_gaps(text: str, value: float) -> str:
    return k.write_number(text, _layout_span(text), "gaps", value)


def read_always_center_single_column(text: str) -> bool | None:
    return k.read_bool_kv(text, _layout_span(text), "always-center-single-column")


def write_always_center_single_column(text: str, value: bool) -> str:
    return k.write_bool_kv(text, _layout_span(text), "always-center-single-column", value)


def read_center_focused_column(text: str) -> str | None:
    return k.read_string(text, _layout_span(text), "center-focused-column")


def write_center_focused_column(text: str, value: str) -> str:
    return k.write_string(text, _layout_span(text), "center-focused-column", value)


def read_focus_ring_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _focus_ring_span(text))


def write_focus_ring_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _focus_ring_span(text), value)


def read_focus_ring_width(text: str) -> float | None:
    return k.read_number(text, _focus_ring_span(text), "width")


def write_focus_ring_width(text: str, value: float) -> str:
    return k.write_number(text, _focus_ring_span(text), "width", value)


def read_border_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _border_span(text))


def write_border_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _border_span(text), value)


def read_shadow_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _shadow_span(text))


def write_shadow_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _shadow_span(text), value)


def read_shadow_softness(text: str) -> float | None:
    return k.read_number(text, _shadow_span(text), "softness")


def write_shadow_softness(text: str, value: float) -> str:
    return k.write_number(text, _shadow_span(text), "softness", value)


def read_shadow_spread(text: str) -> float | None:
    return k.read_number(text, _shadow_span(text), "spread")


def write_shadow_spread(text: str, value: float) -> str:
    return k.write_number(text, _shadow_span(text), "spread", value)


def read_shadow_offset(text: str) -> tuple[float, float] | None:
    return k.read_named_args(text, _shadow_span(text), "offset", ["x", "y"])


def write_shadow_offset(text: str, x: float, y: float) -> str:
    return k.write_named_args(text, _shadow_span(text), "offset", ["x", "y"], [x, y])


def read_shadow_color(text: str) -> str | None:
    return k.read_string(text, _shadow_span(text), "color")


def write_shadow_color(text: str, value: str) -> str:
    return k.write_string(text, _shadow_span(text), "color", value)


def read_animations_enabled(text: str) -> bool | None:
    return k.read_on_off(text, k.find_block(text, _ANIMATIONS))


def write_animations_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, k.find_block(text, _ANIMATIONS), value)


def _animation_span(text: str, name: str) -> tuple[int, int]:
    animations = k.find_block(text, _ANIMATIONS)
    import re
    return k.find_nested_block(text, animations, re.escape(name) + r'\s*\{')


def read_animation_duration_ms(text: str, name: str) -> float | None:
    return k.read_number(text, _animation_span(text, name), "duration-ms")


def write_animation_duration_ms(text: str, name: str, value: float) -> str:
    return k.write_number(text, _animation_span(text, name), "duration-ms", value)


def _blur_span(text: str) -> tuple[int, int]:
    return k.find_block(text, _BLUR)


def read_blur_enabled(text: str) -> bool | None:
    return k.read_on_off(text, _blur_span(text))


def write_blur_enabled(text: str, value: bool) -> str:
    return k.write_on_off(text, _blur_span(text), value)


def read_blur_passes(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "passes")


def write_blur_passes(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "passes", value)


def read_blur_offset(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "offset")


def write_blur_offset(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "offset", value)


def read_blur_noise(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "noise")


def write_blur_noise(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "noise", value)


def read_blur_saturation(text: str) -> float | None:
    return k.read_number(text, _blur_span(text), "saturation")


def write_blur_saturation(text: str, value: float) -> str:
    return k.write_number(text, _blur_span(text), "saturation", value)


def _cursor_span(text: str) -> tuple[int, int]:
    return k.find_block(text, _CURSOR)


def read_cursor_theme(text: str) -> str | None:
    return k.read_string(text, _cursor_span(text), "xcursor-theme")


def write_cursor_theme(text: str, value: str) -> str:
    return k.write_string(text, _cursor_span(text), "xcursor-theme", value)


def read_cursor_size(text: str) -> float | None:
    return k.read_number(text, _cursor_span(text), "xcursor-size")


def write_cursor_size(text: str, value: float) -> str:
    return k.write_number(text, _cursor_span(text), "xcursor-size", value)
