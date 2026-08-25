"""Read/write fields in inputs.kdl's touchpad/mouse/trackpoint/gestures blocks."""
from . import kdl_edit as k

_TOUCHPAD = r'touchpad\s*\{'
_MOUSE = r'mouse\s*\{'
_TRACKPOINT = r'trackpoint\s*\{'
_GESTURES = r'gestures\s*\{'
_VIEW_SCROLL = r'dnd-edge-view-scroll\s*\{'
_WORKSPACE_SWITCH = r'dnd-edge-workspace-switch\s*\{'
_HOT_CORNERS = r'hot-corners\s*\{'


def read_touchpad_tap(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _TOUCHPAD), "tap")


def write_touchpad_tap(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _TOUCHPAD), "tap", enabled)


def read_touchpad_natural_scroll(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _TOUCHPAD), "natural-scroll")


def write_touchpad_natural_scroll(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _TOUCHPAD), "natural-scroll", enabled)


def read_touchpad_scroll_method(text: str) -> str | None:
    return k.read_string(text, k.find_block(text, _TOUCHPAD), "scroll-method")


def write_touchpad_scroll_method(text: str, value: str) -> str:
    return k.write_string(text, k.find_block(text, _TOUCHPAD), "scroll-method", value)


def read_mouse_natural_scroll(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _MOUSE), "natural-scroll")


def write_mouse_natural_scroll(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _MOUSE), "natural-scroll", enabled)


def read_mouse_accel_speed(text: str) -> float | None:
    return k.read_number(text, k.find_block(text, _MOUSE), "accel-speed")


def write_mouse_accel_speed(text: str, value: float) -> str:
    return k.write_number(text, k.find_block(text, _MOUSE), "accel-speed", value)


def read_mouse_accel_profile(text: str) -> str | None:
    return k.read_string(text, k.find_block(text, _MOUSE), "accel-profile")


def write_mouse_accel_profile(text: str, value: str) -> str:
    return k.write_string(text, k.find_block(text, _MOUSE), "accel-profile", value)


def read_trackpoint_natural_scroll(text: str) -> bool:
    return k.read_flag(text, k.find_block(text, _TRACKPOINT), "natural-scroll")


def write_trackpoint_natural_scroll(text: str, enabled: bool) -> str:
    return k.write_flag(text, k.find_block(text, _TRACKPOINT), "natural-scroll", enabled)


def read_trackpoint_accel_speed(text: str) -> float | None:
    return k.read_number(text, k.find_block(text, _TRACKPOINT), "accel-speed")


def write_trackpoint_accel_speed(text: str, value: float) -> str:
    return k.write_number(text, k.find_block(text, _TRACKPOINT), "accel-speed", value)


def _view_scroll_span(text: str) -> tuple[int, int]:
    gestures = k.find_block(text, _GESTURES)
    return k.find_nested_block(text, gestures, _VIEW_SCROLL)


def _workspace_switch_span(text: str) -> tuple[int, int]:
    gestures = k.find_block(text, _GESTURES)
    return k.find_nested_block(text, gestures, _WORKSPACE_SWITCH)


def _hot_corners_span(text: str) -> tuple[int, int]:
    gestures = k.find_block(text, _GESTURES)
    return k.find_nested_block(text, gestures, _HOT_CORNERS)


def read_view_scroll_trigger_width(text: str) -> float | None:
    return k.read_number(text, _view_scroll_span(text), "trigger-width")


def write_view_scroll_trigger_width(text: str, value: float) -> str:
    return k.write_number(text, _view_scroll_span(text), "trigger-width", value)


def read_view_scroll_delay_ms(text: str) -> float | None:
    return k.read_number(text, _view_scroll_span(text), "delay-ms")


def write_view_scroll_delay_ms(text: str, value: float) -> str:
    return k.write_number(text, _view_scroll_span(text), "delay-ms", value)


def read_view_scroll_max_speed(text: str) -> float | None:
    return k.read_number(text, _view_scroll_span(text), "max-speed")


def write_view_scroll_max_speed(text: str, value: float) -> str:
    return k.write_number(text, _view_scroll_span(text), "max-speed", value)


def read_workspace_switch_trigger_height(text: str) -> float | None:
    return k.read_number(text, _workspace_switch_span(text), "trigger-height")


def write_workspace_switch_trigger_height(text: str, value: float) -> str:
    return k.write_number(text, _workspace_switch_span(text), "trigger-height", value)


def read_workspace_switch_delay_ms(text: str) -> float | None:
    return k.read_number(text, _workspace_switch_span(text), "delay-ms")


def write_workspace_switch_delay_ms(text: str, value: float) -> str:
    return k.write_number(text, _workspace_switch_span(text), "delay-ms", value)


def read_workspace_switch_max_speed(text: str) -> float | None:
    return k.read_number(text, _workspace_switch_span(text), "max-speed")


def write_workspace_switch_max_speed(text: str, value: float) -> str:
    return k.write_number(text, _workspace_switch_span(text), "max-speed", value)


def read_hot_corner(text: str, corner: str) -> bool:
    return k.read_flag(text, _hot_corners_span(text), corner)


def write_hot_corner(text: str, corner: str, enabled: bool) -> str:
    return k.write_flag(text, _hot_corners_span(text), corner, enabled)
