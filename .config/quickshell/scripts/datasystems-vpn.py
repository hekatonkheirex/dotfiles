#!/usr/bin/env python3
"""Interactive DATASYSTEMS VPN control; passwords stay in the terminal."""

import fcntl
import hashlib
import ipaddress
import json
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import threading

PROFILE = "DATASYSTEMS-VPN"


def load_profile_settings():
    result = subprocess.run(
        ["nmcli", "--escape", "no", "-g", "vpn.data", "connection", "show", PROFILE],
        capture_output=True, text=True, timeout=5, check=True,
    )
    data = dict(item.strip().split(" = ", 1) for item in result.stdout.strip().split(", ") if " = " in item)
    gateway, user = data.get("gateway", ""), data.get("user", "")
    cert = data.get("trusted-cert", "")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+:[0-9]{1,5}", gateway):
        raise ValueError(f"Configure a valid gateway:port in {PROFILE}")
    if not 1 <= int(gateway.rsplit(":", 1)[1]) <= 65535 or not user or any(c in user for c in "\r\n\x00"):
        raise ValueError(f"Invalid gateway or username in {PROFILE}")
    if cert and not re.fullmatch(r"[0-9a-fA-F]{64}", cert):
        raise ValueError(f"Invalid trusted certificate digest in {PROFILE}")
    return {"gateway": gateway, "user": user, "trusted_cert": cert}


def read_process(pid):
    try:
        directory = Path("/proc") / str(pid)
        stat = (directory / "stat").read_text().rsplit(")", 1)[1].split()
        if (directory / "comm").read_text().strip() != "openfortivpn":
            return None
        raw = (directory / "cmdline").read_bytes()
        args = [part.decode() for part in raw.split(b"\0") if part]
        return {"pid": int(pid), "starttime": stat[19], "args": args,
                "digest": hashlib.sha256(raw).hexdigest()}
    except (OSError, UnicodeError, IndexError, ValueError):
        return None


def option_value(args, long_name, short_name):
    for index, arg in enumerate(args):
        if arg.startswith(long_name + "="):
            return arg.split("=", 1)[1]
        if arg in (long_name, short_name) and index + 1 < len(args):
            return args[index + 1]
    return None


def matches_target(args, settings):
    if not args or Path(args[0]).name != "openfortivpn":
        return False
    host, port = settings["gateway"].rsplit(":", 1)
    # openfortivpn replaces the colon with NUL in its original argv buffer.
    gateway_matches = settings["gateway"] in args[1:] or any(
        args[index:index + 2] == [host, port] for index in range(1, len(args) - 1)
    )
    return (gateway_matches
            and option_value(args[1:], "--username", "-u") == settings["user"]
            and (not settings["trusted_cert"] or
                 option_value(args[1:], "--trusted-cert", None) == settings["trusted_cert"]))


def find_target(settings):
    for directory in Path("/proc").iterdir():
        if directory.name.isdecimal():
            process = read_process(directory.name)
            if process and matches_target(process["args"], settings):
                return process
    return None


def ppp_connected(settings):
    host = settings["gateway"].rsplit(":", 1)[0]
    try:
        addresses = {str(ipaddress.ip_address(host))}
    except ValueError:
        result = subprocess.run(["getent", "ahostsv4", host], capture_output=True, text=True, timeout=3)
        addresses = {line.split()[0] for line in result.stdout.splitlines() if line.strip()}
    result = subprocess.run(["ip", "-j", "address", "show"], capture_output=True, text=True, timeout=3, check=True)
    return any(
        link.get("link_type") == "ppp" and "UP" in link.get("flags", [])
        and any(addr.get("address") in addresses or addr.get("peer", "").split("/")[0] in addresses
                for addr in link.get("addr_info", []))
        for link in json.loads(result.stdout)
    )


def open_lock():
    directory = Path(os.environ["XDG_RUNTIME_DIR"])
    if directory.stat().st_uid != os.getuid():
        raise ValueError("XDG_RUNTIME_DIR does not belong to this user")
    return os.open(directory / "datasystems-vpn.lock", os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)


def locked():
    fd = open_lock()
    try:
        fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        return False
    except BlockingIOError:
        return True
    finally:
        os.close(fd)


def status():
    settings = load_profile_settings()
    connected = bool(find_target(settings)) and ppp_connected(settings)
    return {"connected": connected, "busy": locked() and not connected}


def toggle(detach=False):
    if not locked():
        subprocess.Popen(
            ["kitty", "--class", "datasystems-vpn", "--title", "DATASYSTEMS VPN",
             sys.executable, str(Path(__file__).resolve()), "session"] + (["--detach"] if detach else []),
            stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
            start_new_session=True,
        )
    return 0


# Pin a process handle before checking identity, so a reused numeric PID cannot
# receive the signal. Run only after the user explicitly confirms disconnection.
STOP_CODE = """
import hashlib, os, pathlib, signal, sys
pid = int(sys.argv[1])
fd = os.pidfd_open(pid)
p = pathlib.Path('/proc') / str(pid)
start = (p / 'stat').read_text().rsplit(')', 1)[1].split()[19]
digest = hashlib.sha256((p / 'cmdline').read_bytes()).hexdigest()
if start != sys.argv[2] or digest != sys.argv[3]:
    raise SystemExit('VPN process changed; disconnect canceled')
signal.pidfd_send_signal(fd, signal.SIGINT)
"""


def stop_target(target):
    return subprocess.run(
        ["sudo", "/usr/bin/python3", "-I", "-c", STOP_CODE,
         str(target["pid"]), target["starttime"], target["digest"]], check=False,
    ).returncode


def popen_surviving_hangup(command):
    """Start command so closing its terminal (SIGHUP) cannot kill it."""
    previous = signal.signal(signal.SIGHUP, signal.SIG_IGN)
    try:
        return subprocess.Popen(command)  # SIG_IGN survives exec; sudo restores it for its child
    finally:
        signal.signal(signal.SIGHUP, previous)


def connect(settings, lock_fd, detach=False):
    command = ["sudo", "openfortivpn", "-c", "/dev/null", settings["gateway"],
               "--username=" + settings["user"]]
    if settings["trusted_cert"]:
        command.append("--trusted-cert=" + settings["trusted_cert"])
    print(f"DATASYSTEMS VPN: {settings['gateway']} / {settings['user']}", flush=True)
    if detach:
        print("This terminal closes once connected. Disconnect from the networks window.", flush=True)
    else:
        print("Keep this terminal open. Ctrl+C disconnects. Passwords are not saved.", flush=True)
    child = popen_surviving_hangup(command) if detach else subprocess.Popen(command)
    finished = threading.Event()
    connected = threading.Event()

    def release_when_connected():
        while not finished.wait(1):
            try:
                if find_target(settings) and ppp_connected(settings):
                    fcntl.flock(lock_fd, fcntl.LOCK_UN)
                    connected.set()
                    return
            except (OSError, ValueError, subprocess.SubprocessError):
                continue

    watcher = threading.Thread(target=release_when_connected, daemon=True)
    watcher.start()
    try:
        try:
            while detach and child.poll() is None:
                if connected.wait(0.5):
                    print("Connected.", flush=True)
                    return 0  # tunnel keeps running; the terminal closes
            return child.wait()
        except KeyboardInterrupt:
            # The terminal sends SIGINT to the foreground process group,
            # including sudo, which forwards it to openfortivpn.
            return child.wait()
    finally:
        finished.set()
        watcher.join()


def session(detach=False):
    if not sys.stdin.isatty():
        raise ValueError("VPN credentials require an interactive terminal")
    fd = open_lock()
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            print("A DATASYSTEMS VPN operation is already in progress.")
            return 0
        settings = load_profile_settings()
        target = find_target(settings)
        if target:
            print(f"DATASYSTEMS VPN is already running (PID {target['pid']}).", flush=True)
            if input("Disconnect? This interrupts SSH and other VPN connections. [y/N]: ").strip().lower() not in ("y", "yes"):
                print("Disconnect canceled.")
                return 0
            return stop_target(target)
        return connect(settings, fd, detach)
    finally:
        os.close(fd)


def main():
    action = sys.argv[1] if len(sys.argv) > 1 else ""
    detach = sys.argv[2:] == ["--detach"]
    if sys.argv[2:] not in ([], ["--detach"]) or (detach and action not in ("toggle", "session")):
        action = ""
    try:
        if action == "status":
            print(json.dumps(status()))
            return 0
        if action == "toggle":
            return toggle(detach)
        if action == "session":
            code = session(detach)
            if code not in (0, 130, -2):
                input(f"VPN exited with status {code}. Press Enter to close...")
            return code
        raise ValueError("Usage: datasystems-vpn.py status | toggle [--detach] | session [--detach]")
    except (OSError, ValueError, subprocess.SubprocessError) as error:
        print(f"DATASYSTEMS VPN: {error}", file=sys.stderr)
        if action == "status":
            print(json.dumps({"connected": False, "busy": False}))
        elif action == "session" and sys.stdin.isatty():
            input("Press Enter to close...")
        return 1
    except (EOFError, KeyboardInterrupt):
        return 0


if __name__ == "__main__":
    sys.exit(main())
