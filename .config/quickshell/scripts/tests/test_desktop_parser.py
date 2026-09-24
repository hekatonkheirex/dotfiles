import importlib.util
import json
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


def test_main_honors_hidden_tryexec_and_user_id_precedence(tmp_path, monkeypatch, capsys):
    user_apps = tmp_path / "user" / "applications"
    system_apps = tmp_path / "system" / "applications"
    user_apps.mkdir(parents=True)
    system_apps.mkdir(parents=True)
    (user_apps / "masked.desktop").write_text(
        "[Desktop Entry]\nName=Masked\nExec=app\nHidden=true\n"
    )
    (system_apps / "masked.desktop").write_text(
        "[Desktop Entry]\nName=System fallback\nExec=app\n"
    )
    (user_apps / "override.desktop").write_text(
        "[Desktop Entry]\nName=User version\nExec=user-app\n"
    )
    (system_apps / "override.desktop").write_text(
        "[Desktop Entry]\nName=System version\nExec=system-app\n"
    )
    (user_apps / "unavailable.desktop").write_text(
        "[Desktop Entry]\nName=Unavailable\nTryExec=missing-executable-xyz\nExec=app\n"
    )
    monkeypatch.setattr(desktop_parser, "APP_DIRS", [user_apps, system_apps])
    monkeypatch.setattr(desktop_parser, "CACHE_PATH", tmp_path / "cache.json")
    monkeypatch.setattr(desktop_parser, "CACHE_DIR", tmp_path / "cache")
    desktop_parser.main()
    apps = json.loads(capsys.readouterr().out)
    assert [(app["name"], app["argv"]) for app in apps] == [
        ("User version", ["user-app"])
    ]


def test_desktop_file_edits_invalidate_cache(tmp_path, monkeypatch, capsys):
    appdir = tmp_path / "applications"
    appdir.mkdir()
    desktop_file = appdir / "app.desktop"
    desktop_file.write_text("[Desktop Entry]\nName=Before\nExec=app\n")
    monkeypatch.setattr(desktop_parser, "APP_DIRS", [appdir])
    monkeypatch.setattr(desktop_parser, "CACHE_PATH", tmp_path / "cache.json")
    monkeypatch.setattr(desktop_parser, "CACHE_DIR", tmp_path / "cache")

    desktop_parser.main()
    assert json.loads(capsys.readouterr().out)[0]["name"] == "Before"
    desktop_file.write_text("[Desktop Entry]\nName=After\nExec=app\n")
    desktop_parser.main()
    assert json.loads(capsys.readouterr().out)[0]["name"] == "After"
