import argparse
import os
import sys
from pathlib import Path

from . import outputs as o
from . import inputs as i
from . import decorations as d
from .config_file import NiriConfigFile

DEFAULT_PATHS = {
    "outputs": os.path.expanduser("~/.config/niri/outputs.kdl"),
    "inputs": os.path.expanduser("~/.config/niri/inputs.kdl"),
    "decorations": os.path.expanduser("~/.config/niri/decorations.kdl"),
}

# field -> (read_fn, write_fn, value_type, needs_arg)
# read_fn(text, *args) -> value; write_fn(text, *args, value) -> new_text
_FIELDS = {
    "outputs": {
        "scale": (o.read_scale, o.write_scale, float, True),
        "transform": (o.read_transform, o.write_transform, str, True),
        "mode": (o.read_mode, o.write_mode, str, True),
    },
    "inputs": {
        "touchpad-tap": (i.read_touchpad_tap, i.write_touchpad_tap, bool, False),
        "touchpad-natural-scroll": (i.read_touchpad_natural_scroll, i.write_touchpad_natural_scroll, bool, False),
        "touchpad-scroll-method": (i.read_touchpad_scroll_method, i.write_touchpad_scroll_method, str, False),
        "mouse-natural-scroll": (i.read_mouse_natural_scroll, i.write_mouse_natural_scroll, bool, False),
        "mouse-accel-speed": (i.read_mouse_accel_speed, i.write_mouse_accel_speed, float, False),
        "mouse-accel-profile": (i.read_mouse_accel_profile, i.write_mouse_accel_profile, str, False),
        "trackpoint-natural-scroll": (i.read_trackpoint_natural_scroll, i.write_trackpoint_natural_scroll, bool, False),
        "trackpoint-accel-speed": (i.read_trackpoint_accel_speed, i.write_trackpoint_accel_speed, float, False),
        "view-scroll-trigger-width": (i.read_view_scroll_trigger_width, i.write_view_scroll_trigger_width, float, False),
        "view-scroll-delay-ms": (i.read_view_scroll_delay_ms, i.write_view_scroll_delay_ms, float, False),
        "view-scroll-max-speed": (i.read_view_scroll_max_speed, i.write_view_scroll_max_speed, float, False),
        "workspace-switch-trigger-height": (i.read_workspace_switch_trigger_height, i.write_workspace_switch_trigger_height, float, False),
        "workspace-switch-delay-ms": (i.read_workspace_switch_delay_ms, i.write_workspace_switch_delay_ms, float, False),
        "workspace-switch-max-speed": (i.read_workspace_switch_max_speed, i.write_workspace_switch_max_speed, float, False),
        "hot-corner": (i.read_hot_corner, i.write_hot_corner, bool, True),
    },
    "decorations": {
        "gaps": (d.read_gaps, d.write_gaps, float, False),
        "always-center-single-column": (d.read_always_center_single_column, d.write_always_center_single_column, bool, False),
        "center-focused-column": (d.read_center_focused_column, d.write_center_focused_column, str, False),
        "focus-ring-enabled": (d.read_focus_ring_enabled, d.write_focus_ring_enabled, bool, False),
        "focus-ring-width": (d.read_focus_ring_width, d.write_focus_ring_width, float, False),
        "border-enabled": (d.read_border_enabled, d.write_border_enabled, bool, False),
        "shadow-enabled": (d.read_shadow_enabled, d.write_shadow_enabled, bool, False),
        "shadow-softness": (d.read_shadow_softness, d.write_shadow_softness, float, False),
        "shadow-spread": (d.read_shadow_spread, d.write_shadow_spread, float, False),
        "shadow-color": (d.read_shadow_color, d.write_shadow_color, str, False),
        "animations-enabled": (d.read_animations_enabled, d.write_animations_enabled, bool, False),
        "animation-duration-ms": (d.read_animation_duration_ms, d.write_animation_duration_ms, float, True),
        "blur-enabled": (d.read_blur_enabled, d.write_blur_enabled, bool, False),
        "blur-passes": (d.read_blur_passes, d.write_blur_passes, float, False),
        "blur-offset": (d.read_blur_offset, d.write_blur_offset, float, False),
        "blur-noise": (d.read_blur_noise, d.write_blur_noise, float, False),
        "blur-saturation": (d.read_blur_saturation, d.write_blur_saturation, float, False),
        "cursor-theme": (d.read_cursor_theme, d.write_cursor_theme, str, False),
        "cursor-size": (d.read_cursor_size, d.write_cursor_size, float, False),
    },
}


def _parse_value(raw: str, value_type):
    if value_type is bool:
        return raw.lower() in ("1", "true", "on", "yes")
    return value_type(raw)


def _format_value(value) -> str:
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(prog="niri_config")
    parser.add_argument("file", choices=list(_FIELDS.keys()))
    parser.add_argument("action", choices=["read", "write"])
    parser.add_argument("field")
    parser.add_argument("rest", nargs="*")
    parser.add_argument("--path", default=None)
    args = parser.parse_args(argv)

    fields = _FIELDS[args.file]
    if args.field not in fields:
        print(f"ERROR: unknown field {args.field!r} for {args.file}", file=sys.stderr)
        return 1
    read_fn, write_fn, value_type, needs_arg = fields[args.field]
    path = args.path or DEFAULT_PATHS[args.file]

    if args.action == "read":
        extra = list(args.rest)
        cfg = NiriConfigFile(path)
        try:
            value = read_fn(cfg.read_text(), *extra)
        except ValueError as exc:
            print(f"ERROR: {exc}", file=sys.stderr)
            return 1
        if value is None:
            print("unset")
            return 0
        print(_format_value(value))
        return 0

    # write: rest = [value, *extra_args] if needs_arg else [value]
    if not args.rest:
        print("ERROR: missing value", file=sys.stderr)
        return 1
    raw_value, *extra = args.rest
    try:
        value = _parse_value(raw_value, value_type)
    except ValueError:
        print(f"ERROR: invalid value {raw_value!r} for field {args.field!r}", file=sys.stderr)
        return 1

    niri_config_dir = (Path.home() / ".config" / "niri").resolve()
    reload_live = Path(path).resolve().parent == niri_config_dir
    cfg = NiriConfigFile(path, reload_live=reload_live)
    try:
        result = cfg.apply(lambda text: write_fn(text, *extra, value))
    except Exception as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    if not result.ok:
        print(f"ERROR: {result.error}", file=sys.stderr)
        return 1
    print("OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
