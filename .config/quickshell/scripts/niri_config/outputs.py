"""Read/write fields on a single named `output "<name>" { ... }` block."""
import re
from . import kdl_edit as k


def _span(text: str, name: str) -> tuple[int, int]:
    return k.find_block(text, r'output\s+"' + re.escape(name) + r'"\s*\{')


def read_scale(text: str, name: str) -> float | None:
    return k.read_number(text, _span(text, name), "scale")


def write_scale(text: str, name: str, value: float) -> str:
    return k.write_number(text, _span(text, name), "scale", value)


def read_transform(text: str, name: str) -> str | None:
    return k.read_string(text, _span(text, name), "transform")


def write_transform(text: str, name: str, value: str) -> str:
    return k.write_string(text, _span(text, name), "transform", value)


def read_mode(text: str, name: str) -> str | None:
    return k.read_string(text, _span(text, name), "mode")


def write_mode(text: str, name: str, value: str) -> str:
    return k.write_string(text, _span(text, name), "mode", value)


def read_position(text: str, name: str) -> tuple[float, float] | None:
    return k.read_named_args(text, _span(text, name), "position", ["x", "y"])


def write_position(text: str, name: str, x: float, y: float) -> str:
    return k.write_named_args(text, _span(text, name), "position", ["x", "y"], [x, y])
