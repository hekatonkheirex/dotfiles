"""Deterministic KDL fragment editing.

Not a general KDL parser. Each function only understands the exact scalar
shapes niri's own config files use (bare flag, `key value`, `key "string"`,
`key true/false`, bare `on`/`off`, `key a=1 b=2`). It locates a field by
regex within a caller-supplied block span and edits only that one line,
so every other byte in the file — including comments — is untouched.
"""
import re


def find_block(text: str, header_pattern: str) -> tuple[int, int]:
    """Return (body_start, body_end): offsets into `text` spanning the
    region strictly between the `{` and matching `}` of the first block
    whose opening line matches `header_pattern`."""
    m = re.search(header_pattern, text)
    if m is None:
        raise ValueError(f"block not found: {header_pattern!r}")
    brace_start = text.index("{", m.start())
    depth = 0
    i = brace_start
    while i < len(text):
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
            if depth == 0:
                return (brace_start + 1, i)
        i += 1
    raise ValueError(f"unclosed block: {header_pattern!r}")


def find_nested_block(text: str, outer_span: tuple[int, int], inner_pattern: str) -> tuple[int, int]:
    """Like find_block, but searches only within outer_span and returns
    offsets translated back into the original `text`."""
    outer_start, outer_end = outer_span
    inner_start, inner_end = find_block(text[outer_start:outer_end], inner_pattern)
    return (outer_start + inner_start, outer_start + inner_end)


def _format_number(value: float) -> str:
    value = float(value)
    return str(int(value)) if value.is_integer() else repr(value)


def _insert_point(block: str) -> int:
    """First line inside a block, right after its opening newline."""
    return block.index("\n") + 1 if "\n" in block else 0


def read_number(text: str, span: tuple[int, int], key: str) -> float | None:
    block = text[span[0]:span[1]]
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]+(-?[0-9]+(?:\.[0-9]+)?)', block)
    return float(m.group(1)) if m else None


def write_number(text: str, span: tuple[int, int], key: str, value: float) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + r'[ \t]+-?[0-9]+(?:\.[0-9]+)?')
    m = pattern.search(block)
    formatted = _format_number(value)
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + formatted + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + formatted + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_string(text: str, span: tuple[int, int], key: str) -> str | None:
    block = text[span[0]:span[1]]
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]+"([^"]*)"', block)
    return m.group(1) if m else None


def write_string(text: str, span: tuple[int, int], key: str, value: str) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + r'[ \t]+"[^"]*"')
    m = pattern.search(block)
    literal = '"' + value + '"'
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + literal + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + literal + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_bool_kv(text: str, span: tuple[int, int], key: str) -> bool | None:
    block = text[span[0]:span[1]]
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + r'[ \t]+(true|false)\b', block)
    return (m.group(1) == "true") if m else None


def write_bool_kv(text: str, span: tuple[int, int], key: str, value: bool) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + r'[ \t]+(?:true|false)\b')
    m = pattern.search(block)
    literal = "true" if value else "false"
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + literal + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + literal + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_flag(text: str, span: tuple[int, int], name: str) -> bool:
    block = text[span[0]:span[1]]
    return re.search(r'(?m)^[ \t]*' + re.escape(name) + r'[ \t]*(?://.*)?$', block) is not None


def write_flag(text: str, span: tuple[int, int], name: str, enabled: bool) -> str:
    block = text[span[0]:span[1]]
    pattern = re.compile(r'(?m)^[ \t]*' + re.escape(name) + r'[ \t]*(?://.*)?\n?')
    m = pattern.search(block)
    if enabled:
        if m:
            return text
        at = _insert_point(block)
        new_block = block[:at] + "  " + name + "\n" + block[at:]
    else:
        if not m:
            return text
        new_block = block[:m.start()] + block[m.end():]
    return text[:span[0]] + new_block + text[span[1]:]


def read_on_off(text: str, span: tuple[int, int]) -> bool | None:
    block = text[span[0]:span[1]]
    if re.search(r'(?m)^[ \t]*on[ \t]*(?://.*)?$', block):
        return True
    if re.search(r'(?m)^[ \t]*off[ \t]*(?://.*)?$', block):
        return False
    return None


def write_on_off(text: str, span: tuple[int, int], enabled: bool) -> str:
    block = text[span[0]:span[1]]
    word = "on" if enabled else "off"
    pattern = re.compile(r'(?m)^([ \t]*)(on|off)[ \t]*(?://.*)?$')
    m = pattern.search(block)
    if m:
        new_block = block[:m.start()] + m.group(1) + word + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + word + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]


def read_named_args(text: str, span: tuple[int, int], key: str, arg_names: list[str]) -> tuple[float, ...] | None:
    block = text[span[0]:span[1]]
    args_pattern = "".join(r'\s+' + re.escape(a) + r'=(-?[0-9]+(?:\.[0-9]+)?)' for a in arg_names)
    m = re.search(r'(?m)^[ \t]*' + re.escape(key) + args_pattern, block)
    return tuple(float(g) for g in m.groups()) if m else None


def write_named_args(text: str, span: tuple[int, int], key: str, arg_names: list[str], values: list[float]) -> str:
    block = text[span[0]:span[1]]
    args_pattern = "".join(r'\s+' + re.escape(a) + r'=-?[0-9]+(?:\.[0-9]+)?' for a in arg_names)
    pattern = re.compile(r'(?m)^([ \t]*)' + re.escape(key) + args_pattern)
    m = pattern.search(block)
    formatted = " ".join(f"{a}={_format_number(v)}" for a, v in zip(arg_names, values))
    if m:
        new_block = block[:m.start()] + m.group(1) + key + " " + formatted + block[m.end():]
    else:
        at = _insert_point(block)
        new_block = block[:at] + "  " + key + " " + formatted + "\n" + block[at:]
    return text[:span[0]] + new_block + text[span[1]:]
