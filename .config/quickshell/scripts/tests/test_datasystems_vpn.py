import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys

import pytest

SPEC = importlib.util.spec_from_file_location("datasystems_vpn", Path(__file__).parents[1] / "datasystems-vpn.py")
vpn = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(vpn)
SETTINGS = {"gateway": "vpn.example.test:10443", "user": "employee", "trusted_cert": "a" * 64}


def argv():
    return ["/usr/bin/openfortivpn", "-c", "/dev/null", SETTINGS["gateway"],
            "--username=employee", "--trusted-cert=" + SETTINGS["trusted_cert"]]


def test_detects_gateway_after_openfortivpn_normalizes_its_argv():
    args = argv()
    args[3:4] = ["vpn.example.test", "10443"]
    assert vpn.matches_target(args, SETTINGS)


@pytest.mark.parametrize("change", ["wrapper", "host", "port", "user", "certificate"])
def test_does_not_target_unrelated_processes(change):
    args = argv()
    if change == "wrapper":
        args = ["/usr/bin/sudo"] + args
    elif change == "host":
        args[3] = "other-vpn.example.test:10443"
    elif change == "port":
        args[3] = "vpn.example.test:443"
    elif change == "user":
        args[4] = "--username=employee-other"
    else:
        args[5] = "--trusted-cert=" + "b" * 64
    assert not vpn.matches_target(args, SETTINGS)


def test_unrelated_ppp_link_does_not_report_target_connected(monkeypatch):
    settings = {**SETTINGS, "gateway": "203.0.113.9:10443"}
    links = [{"link_type": "ppp", "flags": ["UP"], "addr_info": [{"address": "203.0.113.10"}]}]
    monkeypatch.setattr(vpn.subprocess, "run", lambda *a, **k: subprocess.CompletedProcess(a, 0, json.dumps(links)))
    assert not vpn.ppp_connected(settings)
    links[0]["addr_info"][0]["address"] = "203.0.113.9"
    assert vpn.ppp_connected(settings)
    links[0]["flags"] = []
    assert not vpn.ppp_connected(settings)


def test_missing_profile_does_not_fall_back_to_an_invented_target(monkeypatch):
    def missing(*args, **kwargs):
        raise subprocess.CalledProcessError(10, args[0])
    monkeypatch.setattr(vpn.subprocess, "run", missing)
    with pytest.raises(subprocess.CalledProcessError):
        vpn.load_profile_settings()


@pytest.mark.parametrize("changed_identity", ["starttime", "command"])
def test_disconnect_refuses_changed_process_identity(changed_identity):
    child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])
    try:
        proc = Path("/proc") / str(child.pid)
        start = (proc / "stat").read_text().rsplit(")", 1)[1].split()[19]
        digest = hashlib.sha256((proc / "cmdline").read_bytes()).hexdigest()
        if changed_identity == "starttime":
            start = str(int(start) + 1)
        else:
            digest = "0" * 64
        result = subprocess.run([sys.executable, "-I", "-c", vpn.STOP_CODE, str(child.pid), start, digest], capture_output=True)
        assert result.returncode != 0
        assert child.poll() is None
    finally:
        child.terminate()
        child.wait(timeout=5)


def test_disconnect_signals_only_the_process_with_matching_identity():
    child = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])
    other = subprocess.Popen([sys.executable, "-c", "import time; time.sleep(60)"])
    try:
        proc = Path("/proc") / str(child.pid)
        start = (proc / "stat").read_text().rsplit(")", 1)[1].split()[19]
        digest = hashlib.sha256((proc / "cmdline").read_bytes()).hexdigest()
        result = subprocess.run([sys.executable, "-I", "-c", vpn.STOP_CODE, str(child.pid), start, digest], capture_output=True)
        assert result.returncode == 0, result.stderr
        assert child.wait(timeout=5) == -2
        assert other.poll() is None
    finally:
        for process in (child, other):
            if process.poll() is None:
                process.terminate()
            process.wait(timeout=5)
