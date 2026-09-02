import importlib.util
from pathlib import Path


PARSER_PATH = Path(__file__).parents[2] / "bin" / "desktop-parser.py"
SPEC = importlib.util.spec_from_file_location("desktop_parser", PARSER_PATH)
desktop_parser = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(desktop_parser)


def test_parse_exec_returns_arguments_without_shell_evaluation():
    command = 'demo-app --title "hello world" %U'
    assert desktop_parser.parse_exec(command) == ["demo-app", "--title", "hello world"]


def test_parse_exec_preserves_shell_characters_as_arguments():
    command = 'sh -c "printf unsafe; touch /tmp/should-not-run"'
    assert desktop_parser.parse_exec(command) == [
        "sh",
        "-c",
        "printf unsafe; touch /tmp/should-not-run",
    ]
